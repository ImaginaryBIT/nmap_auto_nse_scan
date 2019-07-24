#!/bin/bash
#Author ImaginaryBIT
#Version 1.0

RED='\033[0;31m'
YELLOW='\033[0;33m'
GREEN='\033[0;32m'
NC='\033[0m'

echo -e "${YELLOW}This is a nmap nse scanning automation script"
echo -e "${YELLOW}Scope of testing: all TCP port and top 1000 UDP port"
echo -e "${GREEN}Example: nse 192.168.0.108"
echo -e "${RED}Only work on single IP address"

mkdir nmap
dir=$(pwd)/nmap
dir_nmap=$(whereis nmap|cut -d" " -f 3)/scripts
touch $dir/TCP_open_port.xml
touch $dir/UDP_open_port.xml
touch $dir/nmap_nse_scan_result.log

### phase 1: get all open ports

echo -e "${GREEN}===> scanning all the port${NC}"
nmap -T5 -Pn --open -n --min-rate=1000 --max-retries=2 -p- -oX $dir/TCP_open_port.xml $1
nmap -T5 -Pn --open -n --min-rate=1000 --max-retries=2 -sU -oX $dir/UDP_open_port.xml $1
echo -e "${GREEN}===> scanning on all the port done${NC}"

### phase 2: nse scan on open ports

echo -e "${GREEN}### NSE scanning started ###${NC}"
cat $dir/TCP_open_port.xml|grep "service name"| while read line
do
protocol=$(echo $line | cut -d'"' -f 12)
if(ls $dir_nmap | grep -q "^$protocol")
then
	port=$(echo $line | cut -d'"' -f 4)
	echo -e "${YELLOW}===> scanning on port $port $protocol${NC}"
	nmap -Pn -sV -T4 -p$port --script="$protocol-* and not *-brute" -n $1 >> $dir/nmap_nse_scan_result.log
else
	echo -e "${RED}===> NSE for $protocol not found! continue with default script scan${NC}"
	nmap -Pn -sV -T4 -p$port -sC -n $1 >> $dir/nmap_nse_scan_result.log
fi
done

cat $dir/UDP_open_port.xml|grep "service name"| while read line
do
protocol=$(echo $line | cut -d'"' -f 12)
if(ls $dir_nmap | grep -q "^$protocol")
then
	port=$(echo $line | cut -d'"' -f 4)
	echo -e "${YELLOW}===> scanning on port $port $protocol${NC}"
	nmap -Pn -sU -sV -T4 -p$port --script="$protocol-* and not *-brute" -n $1 >> $dir/nmap_nse_scan_result.log
else
	echo -e "${RED}===> NSE for $protocol not found! continue with default script scan${NC}"
	nmap -Pn -sU -sV -T4 -p$port -sC -n $1 >> $dir/nmap_nse_scan_result.log
fi
done
echo -e "${GREEN}### Scanning finished ###${NC}"

### phase 3: print scanning result

sed '/^Starting Nmap/d;/^Nmap scan report/d;/^Host is up/d;/^Service detection performed/d;/^Nmap done/d;/^MAC Address/d;' $dir/nmap_nse_scan_result.log > $dir/NSE_result.log
cat $dir/NSE_result.log
