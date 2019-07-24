#!/bin/bash
#Author sheldon
#Version 1.0

RED='\033[0;31m'
YELLOW='\033[0;33m'
GREEN='\033[0;32m'

echo "${YELLOW}This is a nmap nse scanning automation script"
echo "${YELLOW}Scope of testing: all TCP port and top 1000 UDP port"
echo "${GREEN}Example: nse 192.168.0.108"
echo "${RED}Only work on single IP address"

mkdir nmap
dir=$(pwd)/nmap
dir_nmap=$(whereis nmap|cut -d" " -f 3)/scripts
touch $dir/TCP_open_port.xml
touch $dir/UDP_open_port.xml
touch $dir/nmap_nse_scan_result.log

### phase 1: get all open ports

echo "${GREEN}===> scanning all the port"
nmap -T5 -Pn --open -n --min-rate=1000 --max-retries=2 -p- -oX $dir/TCP_open_port.xml $1
nmap -T5 -Pn --open -n --min-rate=1000 --max-retries=2 -sU -oX $dir/UDP_open_port.xml $1
echo "${GREEN}===> scanning on all the port done"

### phase 2: nse scan on open ports

echo "${GREEN}### NSE scanning started ###"
cat $dir/TCP_open_port.xml|grep "service name"| while read line
do
protocol=$(echo $line | cut -d'"' -f 12)
if(ls dir_nmap | grep -q "^$protocol")
then
	port=$(echo $line | cut -d'"' -f 4)
	echo "${YELLOW}===> scanning on port $port $protocol"
	nmap -Pn -sV -T4 -p$port --script="$protocol-*" -n $1 >> nmap_nse_scan_result.log
else
	echo "${RED}===> NSE for $protocol not found! continue with default script scan"
	nmap -Pn -sV -T4 -p$port -sC -n $1 >> nmap_nse_scan_result.log
fi
done

cat $dir/UDP_open_port.xml|grep "service name"| while read line
do
protocol=$(echo $line | cut -d'"' -f 12)
if(ls dir_nmap | grep -q "^$protocol")
then
	port=$(echo $line | cut -d'"' -f 4)
	echo "${YELLOW}===> scanning on port $port $protocol"
	nmap -Pn -sU -sV -T4 -p$port --script="$protocol-*" -n $1 >> nmap_nse_scan_result.log
else
	echo "${RED}===> NSE for $protocol not found! continue with default script scan"
	nmap -Pn -sU -sV -T4 -p$port -sC -n $1 >> nmap_nse_scan_result.log
fi
done
echo "${GREEN}### Scanning finished ###"
 
