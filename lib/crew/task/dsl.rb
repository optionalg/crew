module Crew
  class Task
    class DSL
      include Arguments::DSL

      def initialize(task, &blk)
        @task = task
        self._arguments = @task.arguments
        instance_eval(&blk) if blk
      end

      def load(path)
        contents = File.read(path)
        instance_eval(contents, path, 1)
        process_templates contents.split("__END__\n", 2)[1]
      end

      def desc(val)
        @task.desc = val
      end

      def hints(*hints)
        @task.default_hints = hints
      end

      def setup(*hints, &blk)
        add_to_task(:setup, hints, blk)
      end

      def run(*hints, &blk)
        add_to_task(:run, hints, blk)
      end

      def verify(*hints, &blk)
        add_to_task(:verify, hints, blk)
      end

      def test(*hints, &blk)
        add_to_task(:test, hints, blk)
      end

      def block(opts = {}, &blk)
        @task.arguments.define_block(opts, &blk)
      end

      private
      def add_to_task(type, hints, handler)
        method_name = "add_#{type}"
        if hints.empty?
          @task.send(method_name, &handler)
        else
          hints.each { |hint| @task.send(method_name, hint, &handler) }
        end
      end

      def process_templates(data)
        return unless data
        templates = {}
        last_name = nil
        data.each_line do |line|
          if name = line[/^@@ (.*)\n/, 1]
            templates[name] = ''
            last_name = name
          elsif !last_name
            raise
          else
            templates[last_name] << line
          end
        end
        templates.each do |name, contents|
          @task.add_template name, contents
        end
      end
    end
  end
end
