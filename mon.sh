#!/bin/bash

usage() {
  printf "Usage: ./mon.sh [FLAGS] \n \
    Flags: \n \
      -m ARG: The IP address to bind the monitor to \n \
      -k ARG: The IP where consul is running \n"
}

BOOTSTRAP=0
MON_IP=""

while getopts "hbm:vk:i:" OPTION
do
  case $OPTION in
    h)
      usage
      exit 1
      ;;
   k)
     KV_IP=$OPTARG
     ;;
   m)
     MON_IP=$OPTARG
     ;;
   b)
     BOOTSTRAP=1
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

if [[ ${MON_IP} == "" ]];
then
  echo "MON_IP must be given"
  exit 1
fi

if [[ ${BOOTSTRAP} -eq 1 ]]; 
then
  docker run -d -p 8400:8400 -p 8500:8500 -p 8600:53/udp --name=consul progrium/consul -server -bootstrap
  sleep 2
  docker run --rm -d --net=host \
    -e KV_TYPE=consul \
    -e KV_IP=${MON_IP} \
    -e KV_PORT=8500 \
    ceph/daemon populate_kvstore
  sleep 2
fi




#Start the ceph mon
docker run -d --net=host -v /var/lib/ceph/:/var/lib/ceph/ -e MON_IP=${MON_IP} -e CEPH_PUBLIC_NETWORK=${MON_IP}/24 \
            -e KV_TYPE=consul -e KV_IP=${KV_IP} -e KV_PORT=8500 --name=mon ceph/daemon mon

