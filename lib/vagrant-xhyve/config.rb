require "vagrant"
require "iniparse"

module VagrantPlugins
  module XHYVE
    class Config < Vagrant.plugin("2", :config)


      # The number of CPUs to give the VM
      #
      # @return [Fixnum]
      attr_accessor :cpus

      # The number of MBs memory to give the VM
      #
      # @return [Fixnum]
      attr_accessor :memory
      
      # The mac address of the VM
      #
      # @return [String]
      attr_accessor :mac
      
      # The uuid of the VM
      #
      # @return [String]
      attr_accessor :uuid

      def initialize(region_specific=false)
        @cpus   = UNSET_VALUE
        @memory = UNSET_VALUE
        @mac    = UNSET_VALUE
        @uuid   = UNSET_VALUE

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

        @cpus = nil if @cpus == UNSET_VALUE
 
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
