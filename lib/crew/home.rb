module Crew
  class Home
    class UnknownContextError < RuntimeError
      attr_reader :context_name

      def initialize(context_name)
        @context_name = context_name
        super "Could not find context for #{context_name.inspect}"
      end
    end

    CREW_CONF_FILE = "config"

    def self.init(*args)
      opts = args.last.is_a?(Hash) ? args.pop : {}
      path = args.size == 1 ? args.shift : Dir.pwd
      crew_config_path = File.join(path, CREW_CONF_FILE)

      raise "#{CREW_CONF_FILE} file is in the way" if File.exist?(crew_config_path) && !opts[:force]

      hints = Array(opts[:hints] ? opts[:hints] : [])
      template = File.read(File.expand_path("../template/config.erb", __FILE__))
      out = ERB.new(template).result(OpenStruct.new(hints: hints).instance_eval { binding })
      puts "Writing #{CREW_CONF_FILE} file"
      puts "Using hints: #{hints.inspect}" if hints && !hints.empty?
      File.open(crew_config_path, "w") do |f|
        f << out
      end
      new(crew_config_path)
    end

    attr_reader :data_path, :home_path, :task_path, :callbacks, :context, :logger, :in_setup
    attr_accessor :default_context_name, :setup_mode, :default_test_name

    def initialize(path)
      @home_path = File.expand_path(path)
      @task_path = File.join(@home_path, "tasks")
      @data_path = File.join(@home_path, "data")
      @config_path = File.join(@home_path, "config")
      @contexts_path = File.join(@home_path, "contexts")
      @sources = [File.expand_path("../../../.crew/tasks", __FILE__)]
      @callbacks = {before: [], after: []}
      @contexts = {}
      @testers = {}
      @logger = Logger.new
      load!
    end

    def task_new(name)
      dest, path = find_task_in_paths(name, @task_path)
      if path
        raise "Cannot create #{name}, task already in the way"
      else
        path = name_to_path(name)
        template = File.read(File.expand_path("../template/task.crew.erb", __FILE__))
        out = ERB.new(template).result
        puts "Writing #{path} file"
        out_path = File.join(@task_path, path)
        FileUtils.mkdir_p(File.dirname(out_path))
        File.open(out_path, "w") do |f|
          f << out
        end
      end
    end

    def context_new(name)
      load_contexts!
      if @contexts[name]
        raise "Cannot create #{name}, context already in the way"
      else
        template = File.read(File.expand_path("../template/context.rb.erb", __FILE__))
        path = "#{name}.rb"
        out = ERB.new(template).result
        puts "Writing #{path} file"
        out_path = File.join(@contexts_path, path)
        FileUtils.mkdir_p(File.dirname(out_path))
        File.open(out_path, "w") do |f|
          f << out
        end
      end
    end

    def contexts
      @contexts.each do |name, context|
        yield name, context
      end
    end

    def perform_setup
      @in_setup = true
      yield
    ensure
      @in_setup = false
    end

    def task_list
      each_task_for_source(@task_path) do |task|
        yield task
      end
    end

    def task_available
      names = Set.new
      list do |task|
        names << task.name
      end

      @sources.each do |source|
        each_task_for_source(source) do |task|
          task.from_source = source
          yield task, names.include?(task.name)
        end
      end
    end

    def shell(context_name)
      context_name ||= @default_context_name
      in_context(context_name) do
        @context.run "shell" do
          pry
        end
      end
    end

    def docs
      path = Docs.new(self).generate
      puts "Docs generated at #{path}"
      path
    end

    def task_edit(name)
      raise "$EDITOR not defined" unless ENV.key?('EDITOR')
      if source_path = find_task_in_paths(name, @task_path)
        puts "Editing #{source_path[1]} into #{source_path[0]}"
        exec "#{ENV['EDITOR']} #{File.join(source_path)}"
      else
        raise "unable to find task #{name} to install"
      end
    end

    def task_info(name)
      if source_path = find_task_in_paths(name, @task_path)
        puts "Task installed, located at #{File.join(*source_path)}"
      else
        puts "Task #{name} is not installed"
        puts
        @sources.each do |source|
          path = name_to_path(name)
          task_name = File.join(source, path)
          if File.exist?(task_name)
            puts "Task available in #{@source} at #{task_name}"
          else
            puts "Not found in #{@source}"
          end
        end
      end
    end

    def add_tester(context_name, &blk)
      @testers[context_name] = Tester.new(self, context_name, &blk)
    end

    def test(opts = {})
      clean_tests
      @testers.each do |name, tester|
        puts "Running test suite #{name}..."
        tester.run(opts)
      end
    end

    def test_path
      File.join(data_path)
    end

    def task_diff
      only_local = []
      different = []
      each_task do |task|
        source_path = find_task_in_paths(task.name, @sources)
        if source_path.nil?
          only_local << task.path
        elsif File.read(File.join(*source_path)) != File.read(task.path)
          different << [task.path, File.join(*source_path)]
        end
      end
      puts "Diff -- #{only_local.size} tasks only present locally, #{different.size} tasks different"
      unless only_local.empty?
        only_local.each do |dest|
          puts "Only present #{dest}"
        end
      end
      unless different.empty?
        different.each do |(dest, src)|
          puts "Comparing #{dest} with #{src}"
          puts `diff #{dest} #{src}`
        end
      end
    end

    def task_update(name = nil)
      if name
        update_task(name)
      else
        update_all
      end
    end

    def task_install(name)
      if source_path = find_task_in_paths(name, @sources)
        puts "Installing #{source_path[1]} into #{source_path[0]}"
        if add_task(source_path[0], source_path[1])
          puts "Task installed!"
        else
          puts "Nothing done, aready installed"
        end
      else
        raise "unable to find task #{name} to install"
      end
    end

    def task_install_all
      @sources.each do |source|
        each_task_for_source(source) do |task|
          task.from_source = source
          install task.name
        end
      end
    end

    def task_remove(name)
      if path = File.join(@task_path, name_to_path(name))
        if File.exist?(path)
          File.unlink(path)
        end
      else
        raise "unable to find task #{name} to install"
      end
    end

    def add_callback(type, &cb)
      @callbacks[type] << cb
    end

    def run(context_name, name, *args)
      context_name ||= @default_context_name
      in_context(context_name) do
        @context.task(name).run!(*args)
      end
    end

    def add_context(name, file = nil, &blk)
      @contexts[name] = Context.new(self, name, file, &blk)
    end

    def find_task(name)
      find_task_in_paths(name, [@task_path] + @sources)
    end

    def find_and_add_task(name)
      if parts = find_task(name)
        add_task(*parts)
        task_path = File.join(*parts)
        Task.new(self, name, task_path)
      else
        raise "no such task `#{name}'"
      end
    end

    def each_task
      Dir[File.join(@task_path, "**/*.crew")].each do |file|
        name = path_to_name(@task_path, file)
        yield Task.new(self, name, file)
      end
    end

    def each_task_for_source(source)
      Dir[File.join(source, "**/*.crew")].each do |file|
        name = path_to_name(source, file)
        yield Task.new(self, name, file)
      end
    end

    def run_in_context(context_or_name, label, opts = {}, &blk)
      in_context(context_or_name, opts) do
        @context.run(label, &blk)
      end
    end

    def in_context(context_or_name, opts = {})
      previous_context = @context
      @context = case context_or_name
      when Context
        context_or_name
      when Module
        Context.new(self, context_or_name.to_s) do
          adapter(context_or_name, opts)
        end
      when String
        context_name = context_or_name
        @contexts.key?(context_name) ?
          @contexts[context_name] : raise(UnknownContextError.new(context_name))
      end
      begin
        raise UnknownContextError.new(context_or_name) if @context.nil?
        yield
      ensure
        @context = previous_context
      end
    end

    private
    def clean_tests(opts = {})
      digests = Set.new
      each_task do |task|
        digests << task.digest
      end
      Dir[File.join(data_path, "*", "*", "*", "*")].each do |path|
        target_hash = path[/#{Regexp.quote(test_path)}\/(.*)/, 1].gsub('/', '')
        unless digests.include?(target_hash)
          puts "Deleting #{path}..."
          FileUtils.rm_r(path)
        end
      end
    end

    def update_all
      each_task do |task|
        update_task(task.name)
      end
    end

    def update_task(name)
      dest, path = find_task_in_paths(name, @task_path)
      raise "Unable to update task #{name}, not found" if dest.nil?

      if source = find_task_in_paths(name, @sources)
        source_path = File.join(*source)
        return if File.read(source_path) == File.read(File.join(dest, path))
        puts "Updating #{path} from #{source_path}"
        FileUtils.cp source_path, File.join(dest, path)
      end
    end

    def find_task_in_paths(name, paths)
      path = name_to_path(name)
      target_source = Array(paths).find do |source|
        File.exist?(File.join(source, path))
      end
      target_source && [target_source, path]
    end

    def add_task(source, path, force = false)
      added = false
      source_path = File.join(source, path)
      target_path = File.join(@task_path, path)
      unless File.exist?(target_path) || force
        puts "Copying #{source_path} to #{target_path}"
        FileUtils.mkdir_p File.dirname(target_path)
        FileUtils.cp(source_path, target_path)
        added = true
      end
      raise unless File.exist?(target_path)
      added
    end

    def crew_config_path
      File.join(@home, "config.rb")
    end

    def path_to_name(source, path)
      local_path = path[/^#{Regexp.quote(source + "/")}(.*)/, 1]
      local_path.gsub(/\.crew$/, '').gsub(/_$/, '?').gsub('/', "_")
    end

    def name_to_path(name)
      path = File.join(*name.to_s.split("_")) + ".crew"
      path.gsub(/\?\.crew$/, '_.crew')
    end

    def load!
      DSL.new(self).load(@config_path)
      load_contexts!
    end

    def load_contexts!
      Dir[File.join(@contexts_path, "*.rb")].each do |context_file|
        name = File.basename(context_file)[/(.*)\.rb$/, 1]
        add_context(name, context_file)
      end
    end
  end
end
