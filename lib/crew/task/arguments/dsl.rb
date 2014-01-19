module Crew
  class Task
    class Arguments
      module DSL
        attr_accessor :_arguments

        def self.load(arguments, &blk)
          loader = Class.new do
            include DSL
          end.new
          loader._arguments = arguments
          loader.instance_eval(&blk) if blk
        end

        def arg(name, desc = nil, opts = {})
          opts, desc = desc, nil if desc.is_a?(Hash)
          _arguments.define(name, :required, desc, opts)
        end

        def args(name, desc = nil, opts = {})
          opts, desc = desc, nil if desc.is_a?(Hash)
          _arguments.define(name, :glob, desc, opts)
        end

        def opt(name, desc = nil, opts = {})
          opts, desc = desc, nil if desc.is_a?(Hash)
          _arguments.define(name, :opt, desc, opts)
        end
      end
    end
  end
end
