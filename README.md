# Vagrant xhyve Provider

This is a [Vagrant](http://www.vagrantup.com) plugin that adds an [xhyve](http://xhyve.org)
provider to Vagrant.

## Features

* Sorta works

## Limitations

You need to use sudo for most vagrant actions with the xhyve driver,
due to the entitlements needed for xhyve to run without sudo. More details
in the [xhyve github issue](https://github.com/mist64/xhyve/issues/60).

Also, sometimes launching a VM just fails. But I'm not quite sure why.

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

These can be set like typical provider-specific configuration:

```ruby
Vagrant.configure("2") do |config|
  # ... other stuff

  config.vm.provider :xhyve do |xhyve|
    xhyve.cpus = 2
    xhyve.memory = "1G"
  end
end
```
## Synced Folders

There is minimal support for synced folders. Upon `vagrant up`,
`vagrant reload`, and `vagrant provision`, the XHYVE provider will use
`rsync` (if available) to uni-directionally sync the folder to
the remote machine over SSH.

## Questions

Q. Should I use this for my work?

A. Do you want to keep your job? I'm not even sure you should use this for toy
projects.

Q. Why?

A. This project is powered by ignorance and good intentions.

Q. Will I even not have to use sudo?

A. There's a theory in that issue linked above that wrapping xhyve in an
app store app would help. If that were the case, you could probably use the
embedded binary with vagrant-xhyve.

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
