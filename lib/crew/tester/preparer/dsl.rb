module Crew
  class Tester
    class Preparer
      class DSL

        def initialize(preparer)
          @preparer = preparer
        end

        def load(&blk)
          instance_eval(&blk)
        end

        def setup(&blk)
          @preparer.setup = blk
        end

        def include(*includes)
          includes.each do |inc|
            @preparer.add_include(inc)
          end
        end

        def exclude(*excludes)
          excludes.each do |exl|
            @preparer.add_exclude(exl)
          end
        end
      end
    end
  end
end
