module Crew
  class CLI
    class Contexts
      include CLI::Processor

      def process(args)
        cmds = commands
        global_opts = Trollop::options(args) do
          stop_on cmds
        end
        dispatch(args)
      end

      def new(args)
        context_name = args.shift
        raise "You must specify a context name" if context_name.nil?
        crew_home.context_new(context_name)
      end

      def list(args)
        max_name_length = 0
        crew_home.contexts do |context_name, context|
          max_name_length = [max_name_length, context_name.size].max
        end

        crew_home.contexts do |context_name, context|
          space_count = max_name_length - context_name.size + 1
          puts "[#{context_name.color(:cyan)}]#{" " * space_count}Using #{context.adapter_name} adapter from #{context.source}"
        end
      end

      def edit(args)
        context_name = args.shift
        raise "You must specify a context name" if context_name.nil?
        crew_home.context_edit(context_name)
      end

      def info(args)
        context_name = args.shift
        raise "You must specify a context name" if context_name.nil?
        crew_home.context_info(context_name)
      end

      def remove(args)
        context_name = args.shift
        raise "You must specify a context name" if context_name.nil?
        crew_home.context_remove(context_name)
      end

      def help(args)
        puts "# Crew #{Crew::VERSION}".color(:magenta)
        puts
        puts help_message
      end

      def help_message
        <<-HEREDOCS
#{"Contexts                       ".bright}
#{"===============================".bright}

#{"contexts help                  ".color(:blue).bright}provides help

#{"contexts list                  ".color(:blue).bright}lists all the tasks currently installed
#{"contexts new (context name)    ".color(:blue).bright}lists all the tasks available to be installed
#{"contexts remove (context name) ".color(:blue).bright}updates the specified task (or all of them)
#{"contexts edit (context name)   ".color(:blue).bright}lists all the tasks available to be installed
        HEREDOCS
      end

      private
      def commands
        %w(help list new remove edit)
      end
    end
  end
end