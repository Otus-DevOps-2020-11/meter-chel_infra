#!/bin/bash

printf '{' > ./inventory.json
#printf '\n\t"_meta": {\n\t\t"hosts": {\n\t\t\t"hostvars": {}\n\t\t}\n\t},' >> ./inventory.json

printf '\n "all": {\n  "hosts": {\n         '>> ./inventory.json
str=" "
ip=`yc compute instances list | grep "reddit" | grep -v "EXTERNAL IP" | awk -F\| '{print $6}'`
while read -r lin
do
    lin="\"${lin}\",\n"
    str=${str}${lin}
done <<< $ip

str="${str::-3}"
echo -ne $str>> ./inventory.json
printf '\n           }\n   },'>> ./inventory.json

printf '\n "app": {\n  "hosts": {\n         '>> ./inventory.json
str=" "
ip=`yc compute instances list | grep "app" | grep -v "EXTERNAL IP" | awk -F\| '{print $6}'`
while read -r lin
do
    lin="\"${lin}\",\n"
    str=${str}${lin}
done <<< $ip

str="${str::-3}"
echo -ne $str>> ./inventory.json
printf '\n           }\n   },'>> ./inventory.json

printf '\n "db": {\n  "hosts": {\n         '>> ./inventory.json
str=" "
ip=`yc compute instances list | grep "db" | grep -v "EXTERNAL IP" | awk -F\| '{print $6}'`
while read -r lin
do
    lin="\"${lin}\",\n"
    str=${str}${lin}
done <<< $ip

str="${str::-3}"
echo -ne $str>> ./inventory.json
printf '\n           }\n   },'>> ./inventory.json

printf '\n}'>> ./inventory.json
