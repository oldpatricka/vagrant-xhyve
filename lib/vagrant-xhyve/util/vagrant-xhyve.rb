require 'xhyve'

module VagrantPlugins
  module XHYVE
    module Util
      class XhyveGuest < Xhyve::Guest

        def initialize(**opts)
          if opts.has_key? "pid"
            @pid = pid
          else
            @kernel = opts.fetch(:kernel)
            @initrd = opts.fetch(:initrd)
            @cmdline = opts.fetch(:cmdline)
            @blockdevs = [opts[:blockdevs] || []].flatten
            @memory = opts[:memory] || '500M'
            @processors = opts[:processors] || '1'
            @uuid = opts[:uuid] || SecureRandom.uuid
            @serial = opts[:serial] || 'com1'
            @acpi = opts[:acpi] || true
            @networking = opts[:networking] || true
            @foreground = opts[:foreground] || false
            @command = build_command
            @mac = find_mac
          end
        end

        def options
          {
            :pid => @pid,
            :kernel => @kernel,
            :initrd => @initrd,
            :cmdline => @cmdline,
            :blockdevs => @blockdevs,
            :memory => @memory,
            :processors => @processors,
            :uuid => @uuid,
            :serial => @serial,
            :acpi => @acpi,
            :networking => @networking,
            :foreground => @foreground,
            :command => @command,
            :mac => @mac,
            :ip => ip
          }
        end
      end
    end
  end
end
