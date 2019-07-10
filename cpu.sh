#!/bin/bash 
physicalNumber=0
coreNumber=0
logicalNumber=0
HTNumber=0
ModelName=unknow
logicalNumber=$(grep "processor" /proc/cpuinfo|sort -u|wc -l)
physicalNumber=$(grep "physical id" /proc/cpuinfo|sort -u|wc -l)
coreNumber=$(grep "cpu cores" /proc/cpuinfo|uniq|awk -F':' '{print $2}'|xargs)
HTNumber=$((logicalNumber / (physicalNumber * coreNumber))) 
ModelName=$(cat /proc/cpuinfo |grep "model name" |sort -u|awk -F':' '{print $2}')
echo "****** CPU Information ******"
echo "CPU Model name      : ${ModelName}"
echo "Logical CPU Number  : ${logicalNumber}"
echo "Physical CPU Number : ${physicalNumber}"
echo "CPU Core Number     : ${coreNumber}"
echo "HT Number           : ${HTNumber}"
echo "*****************************"