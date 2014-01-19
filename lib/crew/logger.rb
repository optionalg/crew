module Crew
  class Logger
    def initialize(mute = false)
      @indent = 0
      @mute = mute
      writer.sync = true
    end

    def muted
      original_mute = @mute
      @mute = true
      begin
        yield
      ensure
        @mute = original_mute
      end
    end

    def info(text)
      log text
    end

    def sh(command)
      log "#{'$'.color(:blue)} #{command}"
    end

    def cd(dir)
      log "cd #{dir}".color("#aaaaaa")
    end

    def spinner(label)
      muted do
        $stderr.write "  " * @indent
        index = 0
        states = %w(◴ ◷ ◶ ◵)
        spin = proc do |val|
          if index > 0
            $stderr.write "\b" * (label.size + 2)
          end
          if val
            $stderr.write "* ".color(:green)
            $stderr.puts label
          else
            $stderr.write states[index % states.size].color(:yellow)
            $stderr.write " #{label}"
            index += 1
          end
        end
        spin[false]
        spin
      end
    end

    def task(command, args)
      log "#{command} #{args.to_s}".color("#aaaaaa")
      out = nil
      begin
        indent do
          out = yield
        end
        pass_line = "#{'✓'.color(:green)} #{command}"
        pass_line << " #{'# =>'.color(:magenta)} #{out.inspect}"
        log pass_line
        out
      rescue AssertionError
        log "#{'✘'.color(:red)} #{command}"
        raise
      rescue => e
        log "#{'!!!'.color(:blue)} #{command} ([#{e.class}] #{e.message})"
        raise
      end
    end

    def test(name)
      log "Testing #{name.inverse}"
      indent do
        yield
      end
    end

    def pass_test(name)
      log "#{'✓'.color(:green)} Passed test #{name.inverse}"
    end

    def skip_test(name)
      log "#{'/'.color(:yellow)} Skipping test #{name.inverse}"
    end

    def fail_test(name)
      log "#{'✘'.color(:red)} Failing test #{name.inverse}"
    end

    def no_test(name)
      log "#{'≈'.color(:blue)} No tests for #{name}"
    end

    def context(name)
      log "--> [#{name.color(:cyan)}] starting"
      start_time = Time.new.to_f
      indent do
        yield
      end
      end_time = Time.new.to_f
      log "<-- [#{name.color(:cyan)}] ended in %0.2f seconds" % [end_time - start_time]
    end

    def log(line)
      writer.write "  " * @indent
      writer.puts line
    end

    def set_logging(enabled)
      @logging = enabled
    end

    def indent
      @indent += 1
      yield
    ensure
      @indent -= 1
    end

    def writer
      @mute ? StringIO.new : $stderr
    end
  end
end