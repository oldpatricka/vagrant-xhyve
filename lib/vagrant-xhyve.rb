require "pathname"

require "vagrant-xhyve/plugin"

module VagrantPlugins
  module XHYVE
    lib_path = Pathname.new(File.expand_path("../vagrant-xhyve", __FILE__))
    autoload :Action, lib_path.join("action")
    autoload :Errors, lib_path.join("errors")

    # Put vagrant-xhyve-x.y.z/vendor/xhyve-ruby/lib on the LOAD_PATH before
    # the auto-loaded xhyve-ruby-a.b.c
    $LOAD_PATH.unshift(Pathname.new(File.expand_path("../../vendor/xhyve-ruby/lib", __FILE__)))

    # This returns the path to the source of this plugin.
    #
    # @return [Pathname]
    def self.source_root
      @source_root ||= Pathname.new(File.expand_path("../../", __FILE__))
    end
  end
end
