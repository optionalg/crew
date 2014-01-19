require 'timeout'
require 'set'
require 'open3'
require 'io/console'

module Crew
  class Context

    class FailedCommandError < RuntimeError
      attr_reader :command, :out, :err, :status

      def initialize(command, out, err, status)
        @command, @out, @err, @status = command, out, err, status
        super("`#{@command}' failed with status=#{@status} out=#{@out.inspect} err=#{@err.inspect}")
      end
    end

    class TestError < RuntimeError
      def initialize(original_exception, stdout, stderr)
        @original_exception, @stdout, @stderr = original_exception, stdout, stderr
      end

      def to_s
        %|
Error: #{@original_exception.message} (#{@original_exception.class})
#{@original_exception.backtrace.join("\n  ")}

Stderr:
#{@stderr}

Stdout:
#{@stdout}
        |.trim
      end
    end

    include Util

    attr_accessor :opts, :adapter_name, :source
    attr_reader :hints, :home, :name

    def initialize(home, name, file = nil, &blk)
      @home = home
      @name = name
      @hints = Set.new
      @shell_count = 0
      load(file, &blk)
    end

    def load(file = nil, &blk)
      DSL.new(self).load(file, &blk)
    end

    def logger
      @home.logger
    end

    def enter_sudo_password
      unless defined?(@sudo_password)
        puts "Getting your sudo password (just this once):"
        @sudo_password = ENV['SUDO_PASSWORD'] || STDIN.noecho(&:gets).chomp
      end
      nil
    end

    def run(name, *hints, &blk)
      with_callbacks do
        task = Task.new(@home, name) { run &blk }
        task.default_hints = hints
        task.run!
      end
    end

    def with_callbacks
      out = nil
      begin
        @shell_count += 1
        if @shell_count == 1
          logger.context @name do
            start_shell
            out = yield
          end
        else
          out = yield
        end
      ensure
        @shell_count -= 1
        stop_shell if @shell_count == 0
      end
      out
    end

    def run_callbacks(type)
      home.callbacks[type].each do |before|
        run before.source_location.join(':'), &before
      end
    end

    def start_shell
      run_callbacks(:before)
    end

    def stop_shell
      run_callbacks(:after)
    end

    def hint(h)
      @hints << h.to_s
    end

    def sh(cmd, opts = {})
      out, err, code = sh_with_code(cmd, opts)
      assert code.zero?, "Command `#{cmd}' with out: #{out.inspect} err: #{err.inspect} code=#{code}"
      out
    end

    def list
      @home.each_task do |task|
        yield task
      end
    end

    def task(name)
      @home.find_and_add_task(name)
    end

    def register
      @started ||= begin
        start
        true
      end
    end

    def start
    end
  end
end