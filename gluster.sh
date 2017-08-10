#!/bin/bash

# from http://blog.gluster.org/2015/10/linux-scale-out-nfsv4-using-nfs-ganesha-and-glusterfs-one-step-at-a-time/
# few mods due to old article especially around latest install versions plus mods for aws
# Also used https://wiki.centos.org/HowTos/GlusterFSonCentOS
 
# installs
sudo yum -y install epel-release
sudo yum -y update
sudo yum -y install centos-release-gluster
sudo yum -y --enablerepo=centos-gluster*-test install glusterfs-server
sudo yum -y install nfs-ganesha
sudo yum -y install nfs-ganesha-gluster

rpm -qa | grep glusterfs
rpm -qa | grep ganesha

# mount brick on sdb
sudo mkdir -p /bricks/demo
sudo mkfs.xfs /dev/xvdb
sudo mount /dev/xvdb /bricks/demo

# create a directory to be volume
#sudo mkdir /bricks/demo/vol
#sudo mkdir /bricks/demo/scratch


sudo cp /etc/ganesha/ganesha.conf /etc/ganesha/ganesha.conf.old
sudo cat << EOF > /etc/ganesha/ganesha.conf
EXPORT
{
	# Export Id (mandatory, each EXPORT must have a unique Export_Id)
	Export_Id = 1;

	# Exported path (mandatory)
	Path = /simple;

	# Pseudo Path (required for NFS v4)
	Pseudo = /simple;

	# Required for access (default is None)
	# Could use CLIENT blocks instead
	Access_Type = RW;

	# Exporting FSAL
	FSAL {
		Name = GLUSTER;
		Hostname = localhost;
		Volume = simple;
	}
}
EOF

sudo systemctl enable glusterd
sudo systemctl start glusterd.service

# Create gluster volume
sudo gluster volume create simple 10.0.0.10:/bricks/demo/simple
sudo gluster volume set simple nfs.disable on
sudo gluster volume start simple

# Needed otherwise ganesha nfs mount unwritable
chmod 777 /bricks/demo/simple

# Start ganesha
sudo systemctl start nfs-ganesha

# Mount after grace
sleep 10
sudo showmount -e localhost
sudo mkdir /simple
sudo mount localhost:/simple /simple
touch /simple/test
ls -la /simple
ls -la /bricks/demo/simple
