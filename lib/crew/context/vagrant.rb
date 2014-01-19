module Crew
  class Context
    module Vagrant
      include SSH

      def start_shell
        @config_path = "/tmp/vagrant-config-#{$$}"
        `vagrant ssh-config > #{@config_path}`
        raise unless $?.success?
        connect_opts = {}
        user, host = nil, nil
        Net::SSH::Config.load(@config_path, "default").each do |key, value|
          case key
          when 'user' then user = value
          when 'hostname' then host = value
          when 'port' then connect_opts[:port] = Integer(value)
          when 'identityfile' then connect_opts[:keys] = value.first
          when 'identitiesonly' then connect_opts[:keys_only] = value
          when 'host', 'userknownhostsfile', 'stricthostkeychecking', 'passwordauthentication'
            # ignore these
          else warn "don't know #{key.inspect}"; exit(1)
          end
        end
        @_shell = Net::SSH.start(host, user, connect_opts)
      end

      def stop_shell
        @_shell.close if @_shell
        File.unlink(@config_path)
      end
    end
  end
end

