# vagrant-xhyve Box Format

A vagrant-xhyve box, like all vagrant boxes is an archive of a directory of
files with a metadata file, a kernel, ramdisk, and optionally some raw disk
images.

Here's an example:

```
.
|-- block0.img
|-- initrd.gz
|-- metadata.json
`-- vmlinuz
```

The metadata.json just contains the defaults from the vagrant box documentation,
that is it looks like:

```
{
    "provider": "xhyve"
}
```

initrd.gz and vmlinuz are extracted from a raw disk image using the technique
described in Michael Steil's nice blog post 
[introducing xhyve](http://www.pagetable.com/?p=831).

You can have up to ten block devices to attach to your vm, named from block0.img
upto block9.img. You can also have zero. That's ok.

If you would like to use a qcow image, simply name the image block0.qcow to
block9.qcow. Note this will only work with the hyperkit fork of xhyve.
