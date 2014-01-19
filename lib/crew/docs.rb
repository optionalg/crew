module Crew
  class Docs
    def initialize(home)
      @home = home
      @path = File.join(@home.home_path, "docs.html")
    end

    def generate
      template = File.read(File.expand_path("../template/docs.html.erb", __FILE__))
      File.open(@path, 'w') do |file|
        home = @home
        def render_task(task)
          task_template = File.read(File.expand_path("../template/_task.html.erb", __FILE__))
          ERB.new(task_template).result(binding)
        end
        file << ERB.new(template).result(binding)
      end
      @path
    end
  end
end
