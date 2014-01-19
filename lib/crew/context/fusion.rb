module Crew
  class Context
    module Fusion
      include SSH

      attr_accessor :snapshot_name

      def vm_path
        opts.fetch(:path)
      end

      def reset!(name)
        path = vm_path
        @home.run_in_context(Local, "Restoring to `#{name}'") do
          vmrun_snapshots_revert(path, name)
        end
      end

      def prepare_snapshot(name, force = false, &initializer)
        path = vm_path
        fusion_context = self
        @home.run_in_context(Local, "Preparing snapshot `#{name}'") do
          vmrun_snapshots_delete(path, name) if force
          unless vmrun_snapshots(path).include?(name)
            vmrun_snapshots_revert(path, "snapshot")
            @home.run_in_context(fusion_context, "Setting up", &initializer) if initializer
            vmrun_snapshots_create(path, name)
          end
        end
      end

      def start_shell
        path = vm_path
        reset!(@snapshot_name) if @snapshot_name
        @home.run_in_context(Local, "Starting VM") do
          vmrun_start path
        end
        opts[:host] = @home.run_in_context(Local, "Connecting to VM") do
          poll("Getting ip address") { vmrun_getguestipaddress(path) }
        end
        run_callbacks(:before)
      end

      def stop_shell
        if @_shell
          @_shell.close
          @_shell = nil
        end
        @current_dir = nil
        run_callbacks(:after)
        path = vm_path
        #at_exit do
        #  @home.run_in_context(Local, "Suspending VM") do
        #    vmrun_suspend path
        #  end
        #end
      end
    end
  end
end
