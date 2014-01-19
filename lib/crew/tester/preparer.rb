module Crew
  class Tester
    class Preparer

      attr_reader :name
      attr_accessor :setup

      def initialize(name)
        @name = name
        @includes = []
        @excludes = []
      end

      def load(&blk)
        DSL.new(self).load(&blk)
      end

      def match?(name)
        included = @includes.any? { |inc| inc == :all or inc === name }
        included and !@excludes.any? { |exl| exl === name }
      end

      def add_include(inc)
        @includes << inc
      end

      def add_exclude(exl)
        @excludes << exl
      end
    end
  end
end
