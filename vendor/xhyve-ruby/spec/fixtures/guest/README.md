# 

We use tinycore linux, with a small persistence volume that just has openssh.

To regenerate this persistence volume (on osx):

```
# Create a sparse filesystem

dd if=/dev/zero of=loop.img bs=1 count=0 seek=10m

# Mount the image in xhyve, (without opt=vda1) then create a partition table and mkfs.ext4 it.
# It will likely be /dev/vda
# Then reboot with opt=vda
# confirm it's mounted over /opt, then make your changes as per
# http://myblog-kenton.blogspot.ca/2012/03/install-openssh-server-on-tiny-core.html

tce-load -iw openssh.tcz
sudo cp /usr/local/etc/ssh/sshd_config_example /usr/local/etc/ssh/sshd_config
cat >> /opt/.filetool.lst <<EOF
/usr/local/etc/ssh
/etc/passwd
/etc/shadow
EOF

echo "/usr/local/etc/init.d/openssh start" >> /opt/bootlocal.sh 

sudo /usr/local/etc/init.d/openssh start
sudo filetool.sh -b

```

When booting set user=console boot flag, and it will create the console user with password defaulting to 'tcuser'
