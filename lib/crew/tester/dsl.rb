module Crew
  class Tester
    class DSL
      def initialize(tester)
        @tester = tester
      end

      def load(&blk)
        instance_eval(&blk)
      end

      def context(name, &blk)
        @tester.context(name, &blk)
      end

      def hints(*hints)
        @tester.hints = hints
      end

      def prepare(name, &blk)
        @tester.add_preparer(name, &blk)
      end
    end
  end
end
