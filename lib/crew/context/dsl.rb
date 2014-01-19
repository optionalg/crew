module Crew
  class Context
    class DSL
      def initialize(context, &blk)
        @context = context
      end

      def load(file = nil, &blk)
        if file
          instance_eval File.read(file), file, 1
          @context.source = file
        elsif blk
          instance_eval(&blk)
          @context.source = blk.source_location.join(":")
        end
      end

      def adapter(name_or_module, opts = {})
        @context.adapter_name = name_or_module.to_s
        @context.extend name_or_module.is_a?(Module) ? name_or_module : Context.const_get(name_or_module.to_s)
        @context.opts = opts
      end

      def hint(hint)
        @context.hints << hint
      end
    end
  end
end

