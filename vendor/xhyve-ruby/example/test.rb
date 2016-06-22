require 'xhyve'

guest = Xhyve::Guest.new(
    kernel: 'spec/fixtures/guest/vmlinuz',   # path to vmlinuz
    initrd: 'spec/fixtures/guest/initrd',    # path to initrd
    cmdline: 'earlyprintk=true console=ttyS0',   # boot flags to linux
    serial: 'com1',             # com1 / com2 (maps to ttyS0, ttyS1, etc)
    memory: '200M',             # amount of memory in M/G
    processors: 1,              # number of processors
    networking: true,                 # use sudo? (required for network unless signed)
    acpi: true,                 # set up acpi? (required for clean shutdown)
    )

pid = guest.start              # starting the guest spawns an xhyve subprocess, returning the pid
puts pid
puts guest.mac                      # get MAC address of the guest
puts guest.ip                       # get the IP of the guest
