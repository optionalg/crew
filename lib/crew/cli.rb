require 'trollop'

module Crew
  class CLI
    module Processor
      def dispatch(args)
        if commands.include?(args.first)
          method(args.shift.gsub(/-/, '_').to_sym).call(args)
        elsif args.first.nil?
          help(args)
        else
          help(args)
          error "Unknown command #{args.join(", ")}"
        end
      end

      private
      def find_crew_dir
        search_path = Dir.pwd
        while true
          break if File.exist?(File.join(search_path, ".crew"))
          new_path = File.expand_path("..", search_path)
          break if search_path == new_path
          search_path = new_path
        end
        search_path ? File.join(search_path, ".crew") : nil
      end

      def crew_home
        if path = find_crew_dir
          Home.new(path)
        else
          warn "No .crew/config file found"
          exit(1)
        end
      end
    end

    include Processor

    def process(args)
      cmds = commands
      global_opts = Trollop::options(args) do
        opt :no_color, "Don't use colored output"
        stop_on cmds
      end
      Rainbow.enabled = global_opts[:no_color] == false
      dispatch(args)
    end

    ## overall
    def help(args)
      puts help_message
    end

    def init(args)
      opts = Trollop::options(args) do
        opt :force, "Force creation"
      end
      args << opts
      Home.init(*args)
    end

    ## general
    def docs(args)
      opts = Trollop::options(args) do
        opt :open, "Open docs after generation", short: "o"
      end
      path = crew_home.docs
      `open #{path}` if opts[:open]
    end

    # tasks

    def contexts(args)
      Contexts.new.process(args)
    end

    def tasks(args)
      Tasks.new.process(args)
    end

    def shell(args)
      opts = Trollop::options(args) do
        opt :setup, "Enable setup mode", short: "-s"
        opt :context, "Context name", short: "-c", type: String
      end
      home = crew_home
      home.setup_mode = opts[:setup]
      home.shell(opts[:context])
    end

    def run(args)
      opts = Trollop::options(args) do
        opt :setup, "Enable setup mode", short: "-s"
        opt :context, "Context name", short: "-c", type: String
      end
      task_name = args.shift
      raise "You must specify a task name" if task_name.nil?
      home = crew_home
      home.setup_mode = opts[:setup]
      home.run(opts[:context], task_name, *args)
    end

    def test(args)
      opts = Trollop::options(args) do
        opt :force, "Force running", short: "-f"
        opt :fast, "Fail fast"
        opt :failed_only, "Fail fast", short: "-o"
        opt :test_name, "Test name", short: "-t", type: String
        opt :context_name, "Context name", short: "-c", type: String
        opt :force_prepare, "Force preparing", short: "-p"
      end
      crew_home.test(opts)
    end

    private
    def help_message
      <<-HEREDOCS

#{"# Crew #{Crew::VERSION}".color(:magenta)}

#{"General                        ".bright}
#{"===============================".bright}

#{"help                           ".color(:blue).bright}provides help
#{"init                           ".color(:blue).bright}initializes crew
#{"status                         ".color(:blue).bright}gets the current status of crew
#{"docs                           ".color(:blue).bright}generates and opens html docs
#{"test                           ".color(:blue).bright}runs tests

#{Tasks.new.help_message}

#{Contexts.new.help_message}
      HEREDOCS
    end

    def error(message)
      warn message
      exit(1)
    end

    def commands
      %w(help init docs shell run tasks contexts test)
    end
  end
end