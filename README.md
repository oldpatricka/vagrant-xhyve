# Vagrant xhyve Provider

[![Gem Version](https://badge.fury.io/rb/vagrant-xhyve.svg)](https://badge.fury.io/rb/vagrant-xhyve)

This is a [Vagrant](http://www.vagrantup.com) plugin that adds an [xhyve](http://xhyve.org)
provider to Vagrant.

## Features

* Basic features work
* Can work with Hyperkit fork of Xhyve
* qcow image support

## Limitations

You need to use sudo for most vagrant actions with the xhyve driver,
due to the entitlements needed for xhyve to run without sudo. More details
in the [xhyve github issue](https://github.com/mist64/xhyve/issues/60).

## Usage

Install using standard Vagrant plugin installation methods. After
installing, `vagrant up` and specify the `xhyve` provider. An example is
shown below.

```
$ vagrant plugin install vagrant-xhyve
...
$ sudo vagrant up --provider=xhyve
...
```

Of course prior to doing this, you'll need to obtain an xhyve-compatible
box file for Vagrant.

## Quick Start

After installing the plugin (instructions above), you can try an xhyve ubuntu
linux example. This is similar to the example from the xhyve intro blog post.

```
$ mkdir xhyve-vagrant
$ cd xhyve-vagrant
$ vagrant init oldpatricka/ubuntu-14.04
$ sudo vagrant up --provider xhyve
...
```

This will start an Ubuntu Linux instance. you can log in with:

```
$ sudo vagrant ssh
```

## Box Format

The vagrant-xhyve box format is pretty straightforward. See
the [example_box/ directory](https://github.com/oldpatricka/vagrant-xhyve/tree/master/example_box).
That directory also contains instructions on how to build a box.

## Configuration

This provider exposes quite a few provider-specific configuration options:

* `memory` - The amount of memory to give the VM. This can just be a simple
  integer for memory in MB or you can use the suffixed style, eg. 2G for two
  Gigabytes
* `cpus` - The number of CPUs to give the VM
* `xhyve_binary` - use a custom xhyve version
* kernel_command - send a custom kernel boot command
* `vmtype` - The type of VM (kexec or fbsd) 

These can be set like typical provider-specific configuration:

```ruby
Vagrant.configure("2") do |config|
  # ... other stuff

  config.vm.provider :xhyve do |xhyve|
    xhyve.cpus = 2
    xhyve.memory = "1G"
    xhyve.vmtype = "kexec"
    xhyve.xhyve_binary = "/Applications/Docker.app/Contents/MacOS/com.docker.hyperkit"
    xhyve.kernel_command = "root=/dev/mapper/centos-root ro crashkernel=auto rd.lvm.lv=centos/root rd.lvm.lv=centos/swap acpi=off console=ttyS0 LANG=en_GB.UTF-8" # example for a CentOS installed in a LVM filesystem
  end
end
```
## Synced Folders

There is minimal support for synced folders. Upon `vagrant up`,
`vagrant reload`, and `vagrant provision`, the XHYVE provider will use
`rsync` (if available) to uni-directionally sync the folder to
the remote machine over SSH.

## Using Docker's HyperKit Fork of Xhyve

Docker has a very nice port of Xhyve called [HyperKit](https://github.com/docker/hyperkit). It has some interesting features like better stability and qcow support (which this provider can't use yet).

If you want to try it out, either install hyperkit directly, or you can use the version bundled with [Docker for Mac](https://docs.docker.com/engine/installation/mac/). The path to the binary is `/Applications/Docker.app/Contents/MacOS/com.docker.hyperkit`. See the configuration section above for how to use this with the `xhyve_binary` option.

## Questions

Q. Should I use this for my work?

A. Do you want to keep your job? I'm not even sure you should use this for toy
projects.

Q. Why?

A. This project is powered by ignorance and good intentions.

Q. Will I ever not have to use sudo or setuid root?

A. There's a theory in that issue linked above that wrapping xhyve in an
app store app would help. If that were the case, you could probably use the
embedded binary with vagrant-xhyve. Another option is to use setuid root.

Q. This sucks.

A. That's not a question, but why don't you try out [another implementation](https://github.com/sirn/vagrant-xhyve). Looks pretty nice.

## Acknowledgements

This plugin was heavilly cribbed from the vagrant-aws and vagrant-virtualbox
providers. So thanks for those.

This also uses the nice [xhyve-ruby](https://github.com/dalehamel/xhyve-ruby)
gem, by Dale Hamel.

## Development

To work on the `vagrant-xhyve` plugin, clone this repository out, and use
[Bundler](http://gembundler.com) to get the dependencies:

```
$ bundle
```

Once you have the dependencies, verify the unit tests pass with `rake`:

```
$ bundle exec rake
```

If those pass, you're ready to start developing the plugin. You can test
the plugin without installing it into your Vagrant environment by just
creating a `Vagrantfile` in the top level of this directory (it is gitignored)
and add the following line to your `Vagrantfile`
```ruby
Vagrant.require_plugin "vagrant-xhyve"
```
Use bundler to execute Vagrant:
```
$ bundle exec vagrant up --provider=xhyve
```

## Contributors

* Patrick Armstrong
* Nuno Passaro
* Guy Pascarella
