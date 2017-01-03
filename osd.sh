#!/bin/bash

usage() {

printf "Start an OSD container. Mounts a physical device and uses directory type \n \
Usage: osd.sh [Flags] \n \
  Flags: \n \
     -k ARG: IP address where consul is running [mandatory]\n \
     -o ARG: OSD device to use eq: /dev/sdd [mandatory] \n "
}


OSD_DEVICE=""
KV_IP=""

while getopts "hm:o:d:vi:" OPTION
do
  case $OPTION in
    h)
      usage
      exit 1
      ;;
   k) 
     KV_IP=$OPTARG
     ;; 
   d)
     OSD_DEVICE=$OPTARG
     ;;
   v)
     VERBOSE=1
     ;;
   ?)
     usage
     exit 1
    ;;
 esac
done


if [[ $OSD_DEVICE == "" ]];
then
  usage
  exit 1
fi


sudo mkdir -p /var/lib/ceph
sudo chcon -Rt svirt_sandbox_file_t /var/lib/ceph
sudo mkfs.xfs ${OSD_DEVICE} -f
sudo chown -R 64045:64045 /var/lib/ceph/

CEPH_OSD=$(docker exec mon ceph osd create)
sudo mkdir -p /var/lib/ceph/osd/ceph-${CEPH_OSD}
sudo mount ${OSD_DEVICE} /var/lib/ceph/osd/ceph-${CEPH_OSD}/


docker run -d --net=host --privileged=true --pid=host -v /dev/:/dev/ -e OSD_TYPE=directory \
            -v /var/lib/ceph/osd/:/var/lib/ceph/osd/  -e KV_TYPE=consul -e KV_IP=${KV_IP} -e KV_PORT=8500 \
            --name=osd ceph/daemon:tag-build-master-jewel-ubuntu-16.04 osd
