module Crew
  class Home
    class DSL
      def initialize(home)
        @home = home
      end

      def home(path)
        @home.home_path = path
      end

      def before(&cb)
        @home.add_callback(:before, &cb)
      end

      def after(&cb)
        @home.add_callback(:after, &cb)
      end

      def load(path = nil, &blk)
        instance_eval(File.read(path), path, 1) if path
        instance_eval(&blk) if blk
      end

      def context(name, &blk)
        @home.add_context(name, &blk)
      end

      def default_context(name)
        @home.default_context_name = name
      end

      def source(source)
        @home.sources << source
      end

      def hint(hint)
        @home.hints << hint
      end

      def test(name, &blk)
        @home.add_tester(name, &blk)
      end

      def default_test(name)
        @home.default_test_name = name
      end
    end
  end
end
