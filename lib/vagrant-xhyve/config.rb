require "vagrant"
require "iniparse"

module VagrantPlugins
  module XHYVE
    class Config < Vagrant.plugin("2", :config)


      # The number of CPUs to give the VM
      #
      # @return [Fixnum]
      attr_accessor :cpus

      # The amount of memory to give the VM
      #
      # This can just be a simple integer for memory in MB
      # or you can use the suffixed style, eg. 2G for two
      # Gigabytes
      #
      # @return [String]
      attr_accessor :memory


      # The path to the xhyve binary if you don't want to
      # use the one bundled with xhyve-ruby
      #
      # @return [String]
      attr_accessor :xhyve_binary

      # The mac address of the VM
      #
      # @return [String]
      attr_accessor :mac

      # The uuid of the VM
      #
      # @return [String]
      attr_accessor :uuid

      # The kernel command to initialize the machine
      # The default command assumes that the instalation is done directly on the
      # disk and not using a lvm. For example, by default, Centos intallation uses
      # LVM. Moreover, it might be interesting to add new kernel options.
      # @return [String]
      attr_accessor :kernel_command

      def initialize(region_specific=false)
        @cpus           = UNSET_VALUE
        @memory         = UNSET_VALUE
        @xhyve_binary   = UNSET_VALUE
        @mac            = UNSET_VALUE
        @uuid           = UNSET_VALUE
        @kernel_command = UNSET_VALUE

        # Internal state (prefix with __ so they aren't automatically
        # merged)
        @__compiled_region_configs = {}
        @__finalized = false
        @__region_config = {}
        @__region_specific = region_specific
      end

      #-------------------------------------------------------------------
      # Internal methods.
      #-------------------------------------------------------------------

      def finalize!

        @cpus = 1 if @cpus == UNSET_VALUE
        @memory = 1024 if @memory == UNSET_VALUE
        @xhyve_binary = nil if @xhyve_binary == UNSET_VALUE
        @kernel_command = %Q{"earlyprintk=serial console=ttyS0 root=/dev/vda1 ro"} if @kernel_command == UNSET_VALUE
        # Mark that we finalized
        @__finalized = true
      end

      def validate(machine)
        errors = _detected_errors
        { "XHYVE Provider" => errors }
      end
    end
  end
end
