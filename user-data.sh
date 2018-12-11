#!/bin/bash
/usr/bin/curl http://169.254.169.254/latest/meta-data/instance-id/ | sudo tee /var/www/html/index.html
sudo /usr/sbin/parted /dev/sdb mklabel gpt
sudo /usr/sbin/parted -a opt /dev/sdb mkpart primary ext4 0% 100%
sudo /usr/sbin/mkfs.ext4 -L datapartition /dev/sdb1
sudo /usr/bin/mkdir /opt/foo
sudo /usr/bin/mount /dev/sdb1 /opt/foo
/usr/bin/curl http://169.254.169.254/latest/meta-data/instance-id/ | sudo tee /opt/foo/instance-id.txt