module Crew
  class Task
    class Arguments

      class BlockDefinition
        def initialize(opts, &block)
          @opts = opts
          @args = Arguments.new
          Arguments::DSL.load(@args, &block)
        end

        def process(&blk)
          # TODO make better
          blk
        end
      end

      class Definition
        attr_reader :type, :name, :desc

        def initialize(name, type, desc, opts)
          @name, @type, @desc, @opts = name, type, desc, opts
        end

        def value(args, opts)
          val = case @type
          when :required then args.shift
          when :opt      then opts.key?(@name) ? opts[@name] : @opts[:default]
          when :glob     then args.slice!(0, args.size)
          else                raise "unknown #{@name}"
          end
          if @opts[:type] == Integer
            val = Integer(val)
          end
          val
        end

        def required?
          @type == :required
        end

        def glob?
          @type == :glob
        end
      end

      class Proxy
        attr_reader :block

        def initialize(task, params, block)
          @task, @params, @block = task, params, block
        end

        def method_missing(name, *args)
          if @params.key?(name.to_s)
            @params[name.to_s].is_a?(Proc) ? @task.instance_eval(&@params[name.to_s]) : @params[name.to_s]
          else
            super
          end
        end

        def to_s
          @params.empty? ? "" : "(" + @params.map do |k, v|
            val = v.inspect
            if val.size > 50
              val = val[0..22] + "..." + val[-22..-1]
            end
            "#{k}=#{val}"
          end.join(" ") + ")"
        end
      end

      attr_reader :definitions

      def initialize
        @definitions = []
      end

      def process!(args, &blk)
        opts = args.last.is_a?(Hash) ? args.pop : {}
        opts = opts.each_with_object({}){|(k,v), h| h[k.to_s] = v}
        if args.size < minimum_args or (maximum_args && args.size > maximum_args)
          message = "wrong number of arguments (got #{args.size} expected at least #{minimum_args})"
          message << " and at most #{maximum_args}" if maximum_args
          raise ArgumentError, message
        end
        @args = args
        @opts = opts
        @block = @block_definition.process(&blk) if @block_definition
        raise if blk && @block_definition.nil?
      end

      def define(arg, type, desc, opts)
        @definitions << Definition.new(arg, type, desc, opts)
      end

      def define_block(opts, &block)
        @block_definition = BlockDefinition.new(opts, &block)
      end

      def proxy(task)
        args = @args.clone
        @proxy ||= begin
          params = {}
          @definitions.each { |definition| params[definition.name.to_s] = definition.value(args, @opts) }
          Proxy.new(task, params, @block)
        end
      end

      private
      def minimum_args
        required_count
      end

      def maximum_args
        glob_count > 0 ? nil : (total_count - glob_count)
      end

      def required_count
        @definitions.count {|a| a.required? }
      end

      def glob_count
        @definitions.count {|a| a.glob? }
      end

      def total_count
        @definitions.count
      end
    end
  end
end
