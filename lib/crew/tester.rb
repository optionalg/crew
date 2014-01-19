module Crew
  class Tester
    include Util

    attr_accessor :hints

    def initialize(home, name, &blk)
      @name = name
      @home = home
      @context_name = "#{@name}_test"
      @preparers = {}
      DSL.new(self).load(&blk)
    end

    def context(name, &blk)
      if name
        @context_name = name
      else
        @home.add_context @context_name, &blk
      end
    end

    def run(opts)
      return if opts[:context_name] && @name != opts[:context_name]

      prepare(opts[:force_prepare])

      task_count = 0
      test_results = {}

      @home.each_task do |task|
        next unless opts[:test_name].nil? or opts[:test_name] == task.name

        preparer = @preparers.values.find {|p| p.match?(task.name)}
        raise "couldn't find preparer for task `#{task.name}'" unless preparer

        @home.in_context(@context_name) do
          @home.setup_mode = true
          @home.context.snapshot_name = preparer.name
          task.context = @home.context
          task.test!(self, opts) do |result|
            display_result result
          end
        end
      end
    end

    def add_preparer(name, &blk)
      @preparers[name] = Preparer.new(name)
      @preparers[name].load(&blk)
    end

    private
    def display_result(result)
      logger.log "Result was #{result.status} for #{result.task_name}##{result.index} [#{result.context_name}]"
    end

    def prepare(force = false)
      @home.in_context(@context_name) do
        @preparers.each do |name, preparer|
          raise "nooO! #{name}" unless preparer.setup
          @home.context.prepare_snapshot(name, force, &preparer.setup)
        end
      end
    end
  end
end
