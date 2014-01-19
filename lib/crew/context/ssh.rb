module Crew
  class Context
    module SSH
      def current_dir
        @current_dir ||= begin
          result = sh_raw("pwd")
          raise unless result[2] == 0
          result[0].chomp
        end
      end

      def cd(target_dir)
        with_callbacks do
          previous_current_dir = current_dir
          @current_dir = File.expand_path(target_dir, previous_current_dir)
          @home.logger.cd @current_dir
          if block_given?
            begin
              yield
            ensure
              @home.logger.cd previous_current_dir
              cd previous_current_dir
            end
          end
        end
      end

      def sh_with_code(cmd, sh_opts)
        original_cmd = cmd
        runner = "bash -l -c %s"
        stdin = nil
        cmd = "cd #{escape(current_dir)} && #{cmd}"
        if sh_opts[:sudo]
          enter_sudo_password
          if @sudo_password && !opts[:dont_use_sudo_password]
            raw_cmd = cmd
            @home.logger.sh "SUDO (using password) #{original_cmd}"
            cmd = "sudo -S #{runner % escape(cmd)}"
            stdin = "#{@sudo_password}\n"
          else
            @home.logger.sh "SUDO (using not password) #{original_cmd}"
            cmd = "sudo #{runner % escape(cmd)}"
          end
        else
          @home.logger.sh original_cmd
          cmd = runner % escape(cmd)
        end
        sh_raw cmd, stdin
      end

      def sh_raw(cmd, stdin = nil)
        with_callbacks do
          stdout_data = ""
          stderr_data = ""
          exit_code = nil
          exit_signal = nil
          _shell.open_channel do |channel|
            channel.exec(cmd) do |ch, success|
              channel.on_data do |ch,data|
                stdout_data << data
              end

              channel.on_extended_data do |ch,type,data|
                stderr_data << data
              end

              channel.on_request("exit-status") do |ch,data|
                exit_code = data.read_long
              end

              channel.on_request("exit-signal") do |ch, data|
                exit_signal = data.read_long
              end

              if stdin
                channel.send_data stdin
                channel.eof!
              end
            end
          end
          _shell.loop
          [stdout_data, stderr_data, exit_code, exit_signal]
        end
      end

      def save_data(data, target_path)
        sh "echo -n #{escape(data)} > #{escape(target_path)}", stdin_data: data
      end

      def save_file(local_path, target_path)
        with_callbacks do
          raise "#{local_path} does not exist" unless File.exist?(local_path)
          _shell.scp.upload! local_path, target_path
        end
      end

      def reconnect!
        @_shell = nil
      end

      private
      def _shell
        @_shell ||= begin
          retryable do
            connect_opts = Net::SSH::Config.for(opts.fetch(:host))
            @user = connect_opts[:user] || opts.fetch(:user)
            @host = opts.fetch(:host)
            @sudo_password = connect_opts[:password] = opts[:password] if opts[:password]
            connect_opts[:paranoid] = opts[:paranoid] if opts.key?(:paranoid)
            ssh = Net::SSH.start(@host, @user, connect_opts)
            ssh
          end
        end
      end
    end
  end
end
