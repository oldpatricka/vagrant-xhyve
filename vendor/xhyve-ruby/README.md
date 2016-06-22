![](https://travis-ci.org/dalehamel/xhyve-ruby.svg)

# Ruby Xhyve

This is a simple ruby-wrapper around [xhyve](https://github.com/mist64/xhyve), allowing you to start hypervisor Guests on OS-X

# Usage

You can run a guest fairly easily:

```
require 'xhyve'

guest = Xhyve::Guest.new(
    kernel: 'guest/vmlinuz',   # path to vmlinuz
    initrd: 'guest/initrd',    # path to initrd
    cmdline: 'console=tty0',   # boot flags to linux
    blockdevs: 'loop.img',     # path to img files to use as block devs
    uuid: 'a-valid-uuid',      # a valid UUID
    serial: 'com2',            # com1 / com2 (maps to ttyS0, ttyS1, etc)
    memory: '200M',            # amount of memory in M/G
    processors: 1,             # number of processors
    networking: true,          # Enable networking? (requires sudo)
    acpi: true,                 # set up acpi? (required for clean shutdown)
    )

pid = guest.start              # starting the guest spawns an xhyve subprocess, returning the pid
guest.running?                 # is the guest running?
guest.ip                       # get the IP of the guest
guest.mac                      # get MAC address of the guest
guest.stop                     # stop the guest
guest.destroy                  # forcefully stop the guest
```
