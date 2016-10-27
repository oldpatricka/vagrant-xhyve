require "pathname"

require "vagrant/action/builder"

module VagrantPlugins
  module XHYVE
    module Action
      # Include the built-in modules so we can use them as top-level things.
      include Vagrant::Action::Builtin

      def self.action_package
        Vagrant::Action::Builder.new.tap do |b|
          b.use Call, IsCreated do |env, b2|
            if !env[:result]
              b2.use MessageNotCreated
              next
            end

            # Connect to AWS and then Create a package from the server instance
            #b2.use ConnectAWS
            b2.use PackageInstance
          end
        end
      end

      # This action is called to halt the remote machine.
      def self.action_halt
        Vagrant::Action::Builder.new.tap do |b|
          b.use ConfigValidate
          b.use ReadState
          b.use Call, IsCreated do |env, b2|
            if env[:result]
              b2.use Call, GracefulHalt, :stopped, :running do |env2, b3|
                if !env2[:result]
                  b3.use StopInstance
                end
              end
            else
              b2.use MessageNotCreated
            end
          end
        end
      end

      # This action is called to terminate the remote machine.
      def self.action_destroy
        Vagrant::Action::Builder.new.tap do |b|
          b.use Call, DestroyConfirm do |env, b2|
            if env[:result]
              b2.use ConfigValidate
              b2.use Call, IsCreated do |env2, b3|
                if !env2[:result]
                  b3.use MessageNotCreated
                  next
                end
                b3.use TerminateInstance
                #b3.use ProvisionerCleanup if defined?(ProvisionerCleanup)
              end
            else
              b2.use MessageWillNotDestroy
            end
          end
        end
      end

      # This action is called when `vagrant provision` is called.
      def self.action_provision
        Vagrant::Action::Builder.new.tap do |b|
          b.use ConfigValidate
          b.use Call, IsCreated do |env, b2|
            if !env[:result]
              b2.use MessageNotCreated
              next
            end

            b2.use Provision
          end
        end
      end

      # This action is called to read the SSH info of the machine. The
      # resulting state is expected to be put into the `:machine_ssh_info`
      # key.
      def self.action_read_ssh_info
        Vagrant::Action::Builder.new.tap do |b|
          b.use ConfigValidate
          b.use ReadSSHInfo
        end
      end

      # This action is called to read the state of the machine. The
      # resulting state is expected to be put into the `:machine_state_id`
      # key.
      def self.action_read_state
        Vagrant::Action::Builder.new.tap do |b|
          b.use ConfigValidate
          b.use ReadState
        end
      end

      # This action is called to SSH into the machine.
      def self.action_ssh
        Vagrant::Action::Builder.new.tap do |b|
          b.use ConfigValidate
          b.use Call, IsCreated do |env, b2|
            if !env[:result]
              b2.use MessageNotCreated
              next
            end

            b2.use SSHExec
          end
        end
      end

      def self.action_ssh_run
        Vagrant::Action::Builder.new.tap do |b|
          b.use ConfigValidate
          b.use Call, IsCreated do |env, b2|
            if !env[:result]
              b2.use MessageNotCreated
              next
            end

            b2.use SSHRun
          end
        end
      end

      def self.action_prepare_boot
        Vagrant::Action::Builder.new.tap do |b|
          b.use Import
          b.use Provision
          b.use SyncedFolders
        end
      end

      # This action is called to bring the box up from nothing.
      def self.action_up
        Vagrant::Action::Builder.new.tap do |b|
          b.use HandleBox
          b.use ConfigValidate
          b.use BoxCheckOutdated
          b.use Call, IsCreated do |env1, b1|
            if not env1[:result]
              b1.use action_prepare_boot
            end

            b1.use Boot # launch a new instance
          end
        end
      end

      def self.action_reload
        Vagrant::Action::Builder.new.tap do |b|
          b.use ConfigValidate
          b.use Call, IsCreated do |env, b2|
            if !env[:result]
              b2.use MessageNotCreated
              next
            end

            b2.use action_halt
            b2.use Call, WaitForState, :stopped, 120 do |env2, b3|
              if env2[:result]
                b3.use action_up
              else
                # TODO we couldn't reach :stopped, what now?
              end
            end
          end
        end
      end

      # The autoload farm
      action_root = Pathname.new(File.expand_path("../action", __FILE__))
      autoload :IsCreated, action_root.join("is_created")
      autoload :IsStopped, action_root.join("is_stopped")
      autoload :MessageAlreadyCreated, action_root.join("message_already_created")
      autoload :MessageNotCreated, action_root.join("message_not_created")
      autoload :MessageWillNotDestroy, action_root.join("message_will_not_destroy")
      autoload :PackageInstance, action_root.join("package_instance")
      autoload :ReadSSHInfo, action_root.join("read_ssh_info")
      autoload :ReadState, action_root.join("read_state")
      autoload :Import, action_root.join("import")
      autoload :Boot, action_root.join("boot")
      autoload :StartInstance, action_root.join("start_instance")
      autoload :StopInstance, action_root.join("stop_instance")
      autoload :TerminateInstance, action_root.join("terminate_instance")
      autoload :TimedProvision, action_root.join("timed_provision") # some plugins now expect this action to exist
      autoload :WaitForState, action_root.join("wait_for_state")
    end
  end
end
