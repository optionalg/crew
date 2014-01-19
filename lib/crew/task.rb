module Crew
  class Task
    include Util

    NoMatchingHintsError = Class.new(RuntimeError)

    attr_accessor :desc, :context, :default_hints
    attr_reader :name, :arguments, :path, :home

    def initialize(home, name, load_path = nil, &dsl_blk)
      @home, @name, @load_path, @dsl_blk = home, name, load_path, dsl_blk
      @context = @home.context
      reset!
    end

    def installed?
      File.exist?(@load_path) && @load_path.start_with?(home_dir)
    end

    def home_dir
      @home.home_path
    end

    def reset!
      @desc = ""
      @templates = {}
      @arguments = Arguments.new
      @setups = {}
      @verifiers = {}
      @runners = {}
      @tests = []
      @default_hints = []
      dsl = DSL.new(self, &@dsl_blk)
      dsl.load(@load_path) if @load_path
    end

    def source
      File.read(@load_path)
    end

    def args
      @arguments.proxy(self)
    end

    def untested?
      @tests.empty?
    end

    def passing?
      results = Dir[File.join(all_tests_path_prefix, "**", "*.json")].collect do |result|
        JSON.parse(File.read(result))['status']
      end
      results.uniq!
      results.all? {|r| %w(pass skip).include?(r)}
    end

    def method_missing(name, *args, &blk)
      if t = task(name.to_s)
        t.run!(*args, &blk)
      else
        super(name, *args, &blk)
      end
    end

    def cd(dir, &blk)
      @context.cd(dir, &blk)
    end

    def sh(cmd, opts = {})
      @context.sh(cmd, opts)
    end

    def sh_with_code(cmd, opts = {})
      @context.sh_with_code(cmd, opts)
    end

    def task(name)
      @context.task(name)
    end

    def save_data(*args)
      @context.save_data(*args)
    end

    def save_file(*args)
      @context.save_file(*args)
    end

    def hint(h)
      @context.hint(h)
    end

    def hints
      @context.hints
    end

    def reconnect!
      @context.reconnect!
    end

    def run!(*incoming_args, &blk)
      reset!
      @context.with_callbacks do
        @arguments.process!(incoming_args, &blk)
        @context.logger.task(@name, args) do
          success = false
          task_finished = false

          @context.home.perform_setup { setup }
          raise "task '#{@name}' has been called from within setup, but, has no verifier" if @context.home.in_setup && !verifiable?
          success = verifiable? && verified?
          unless success
            raise "can't perform `#{@name}' because we're in setup mode, but, we're not actually performing the setup" if @context.home.in_setup && !@context.home.setup_mode
            @out = run
            if verifiable?
              @out = nil
              verified? or raise "validator for '#{@name}' failed after the task completed successfully"
            end
          end
          @out
        end
      end
    end

    def digest
      Digest::SHA1.hexdigest(source)
    end

    def test!(tester, opts = {})
      @tests.each_with_index do |(hints, test_block), index|
        force = opts[:force]
        skip = !hints.all? {|h| tester.hints.include?(h)}
        test = Test.new(self, test_path_prefix, index, skip, test_block)
        if test.result.status == 'fail' && opts[:failed_only]
          force = true
        end
        test.clear_cached_result! if force
        yield test.run_test!(opts[:fast])
      end
      clear_extra_results!
    end

    def add_template(name, contents)
      @templates[name] = contents
    end

    def template(name, locals = {})
      template = @templates.fetch(name)
      ERB.new(template).result(OpenStruct.new(locals).instance_eval { binding })
    end

    def add_test(*hints, &test)
      @tests << [(@default_hints + hints).map(&:to_s), test]
    end

    def add_setup(*hints, &block)
      add_to_list(@setups, hints, block)
    end

    def add_verify(*hints, &block)
      add_to_list(@verifiers, hints, block)
    end

    def add_run(*hints, &block)
      add_to_list(@runners, hints, block)
    end

    def verify
      eval_for_matching_hints(@verifiers) { raise_no_matching_hints }
    end

    def setup
      eval_for_matching_hints(@setups)
    end

    private
    def raise_no_matching_hints
      raise NoMatchingHintsError, "#{@name} with hints #{@context.hints.to_a}"
    end

    def add_to_list(list, hints, block)
      # TODO
      raise "task #{@name} tries to add an empty blah" unless block && list
      combined_hints = (@default_hints + hints).map(&:to_s)
      list[combined_hints] = block
    end

    def eval_for_matching_hints(list, *args)
      matching_hints = list.keys.sort_by {|hints| hints.length}.reverse.find do |hints|
        hints.all? { |h| @context.hints.include?(h) }
      end
      if matching_hints
        instance_exec(*args, &list[matching_hints])
      else
        yield if block_given?
      end
    end

    def all_tests_path_prefix
      parts = digest.match(/^(..)(..)(..)(.*)/)
      File.join(@home.test_path, parts[1], parts[2], parts[3], parts[4], "tests")
    end

    def test_path_prefix
      raise unless @context
      File.join(all_tests_path_prefix, @context.name)
    end

    def run
      eval_for_matching_hints(@runners) {
        raise_no_matching_hints
      }
    end

    def verifiable?
      !@verifiers.empty?
    end

    def verified?
      !verifiable? or begin
        verify
      rescue AssertionError
        false
      else
        true
      end
    end

    def clear_extra_results!
      index = @tests.size
      while path = File.join(test_path_prefix, "#{index}.json")
        return unless File.exist?(path)
        File.unlink(path)
        index += 1
      end
    end

    def clear_cached_results!
      FileUtils.rm_rf(test_path_prefix)
    end
  end
end
