module Crew
  class Context
    module Local
      def start_shell
        @pwds ||= [Dir.pwd]
        super
      end

      def stop_shell
        super
      end

      def cd(dir)
        @pwds.push dir
        @home.logger.cd dir
        if block_given?
          begin
            yield
          ensure
            @pwds.pop
            @home.logger.cd @pwds.last
          end
        end
      end

      def sh_raw(cmd, stdin = nil)
        stdout_str, stderr_str, status = Open3.capture3(cmd, opts)
        [stdout_str, stderr_str, status.exitstatus]
      end

      def sh_with_code(cmd, opts = {})
        runner = "bash -l -c %s"
        stdin = nil
        opts[:chdir] ||= File.expand_path(@pwds.last, @pwds[-2])
        if opts[:sudo]
          enter_sudo_password
          stdin ||= @sudo_password
          opts = { stdin_data: @sudo_password }
          @home.logger.sh "SUDO #{cmd}"
          cmd = "sudo -S #{runner % escape(cmd)}"
        else
          @home.logger.sh cmd
          cmd = runner % escape(cmd)
        end
        sh_raw cmd, stdin
      end

      def save_data(data, target_path)
        with_callbacks do
          @home.logger.sh "Saving #{data.size} bytes to #{target_path}"
          File.open(target_path, 'w') { |f| f << data }
        end
      end

      def save_file(local_path, target_path)
        with_callbacks do
          @home.logger.sh "Saving #{local_path} bytes to #{target_path}"
          system("cp #{escape(local_path)} #{escape(target_path)}")
        end
      end

      def reconnect!
        @context.reconnect!
      end
    end
  end
end