require "vagrant"

module VagrantPlugins
  module XHYVE
    module Errors
      class VagrantXHYVEError < Vagrant::Errors::VagrantError
        error_namespace("vagrant_xhyve.errors")
      end

      class RsyncError < VagrantXYHVEError
        error_key(:rsync_error)
      end

      class MkdirError < VagrantXHYVEError
        error_key(:mkdir_error)
      end
    end
  end
end
