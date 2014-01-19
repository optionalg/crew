module Crew
  class CLI
    class Tasks
      include CLI::Processor

      def process(args)
        cmds = commands
        global_opts = Trollop::options(args) do
          stop_on cmds
        end
        dispatch(args)
      end

      def new(args)
        task_name = args.shift
        raise "You must specify a task name" if task_name.nil?
        crew_home.new(task_name)
      end

      def update(args)
        opts = Trollop::options(args) do
          opt :all, "Update all", short: "-a"
        end
        task_name = args.shift
        raise "must specify task name or use -a to update all tasks" if task_name.nil? && !opts[:all]
        crew_home.task_update(task_name)
      end

      def diff(args)
        crew_home.task_diff
      end

      def available(args)
        sources = Set.new
        crew_home.available do |task, installed|
          unless sources.include?(task.from_source)
            puts "#{task.from_source}\n#{'=' * task.from_source.size}"
            sources << task.from_source
          end
          print ' '
          print installed ? "i".color(:blue) : " "
          print task.untested? ? "!".color(:red) : " "
          puts " %-30s : %s" % [task.name.bright, task.desc.color("#888888")]
        end
      end

      def list(args)
        max_name_length = 0
        crew_home.task_list do |task|
          max_name_length = [max_name_length, task.name.size].max
        end
        crew_home.task_list do |task|
          install = if task.installed?
            "i".color(:green)
          else
            ' '
          end
          test_status = if task.untested?
            "x".color(:red).blink
          elsif task.passing?
            "√".color(:green)
          else
            'f'.color(:red)
          end
          print ' ' + install + test_status
          puts " %-#{max_name_length}s : %s" % [task.name, task.desc]
        end
      end

      def edit(args)
        task_name = args.shift
        raise "You must specify a task name" if task_name.nil?
        crew_home.task_edit(task_name)
      end

      def info(args)
        task_name = args.shift
        raise "You must specify a task name" if task_name.nil?
        crew_home.task_info(task_name)
      end

      def install(args)
        task_name = args.shift
        raise "You must specify a task name" if task_name.nil?
        crew_home.task_install(task_name)
      end

      def install_all(args)
        crew_home.task_install_all
      end

      def remove(args)
        task_name = args.shift
        raise "You must specify a task name" if task_name.nil?
        crew_home.task_remove(task_name)
      end

      def help(args)
        puts "# Crew #{Crew::VERSION}".color(:magenta)
        puts
        puts help_message
      end

      def help_message
        <<-HEREDOCS
#{"Tasks                          ".bright}
#{"===============================".bright}

#{"tasks help                     ".color(:blue).bright}provides help

#{"tasks list                     ".color(:blue).bright}lists all the tasks currently installed
#{"tasks available                ".color(:blue).bright}lists all the tasks available to be installed
#{"tasks update (task name)       ".color(:blue).bright}updates the specified task (or all of them)
#{"tasks diff (task name)         ".color(:blue).bright}shows the differences between the task from source and your local copy
#{"tasks install [task name]      ".color(:blue).bright}installs a task
#{"tasks remove [task name]    ".color(:blue).bright}removes a task
#{"tasks new [task name]          ".color(:blue).bright}edits a task
#{"tasks edit [task name]         ".color(:blue).bright}edits a task
#{"tasks info [task name]         ".color(:blue).bright}shows information about a specific task
        HEREDOCS
      end

      private
      def commands
        %w(help new install uninstall delete list edit info install install-all uninstall available update diff)
      end
    end
  end
end