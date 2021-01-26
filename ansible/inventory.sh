#!/bin/bash

for group in app db
    do
    str="  "$group:' {\n        "hosts": {\n         '
    ip=`yc compute instances list | grep ${group} | grep -v "EXTERNAL IP" | awk -F\| '{print $6}'`

	while read -r lin
	    do
	    lin="\"${lin}\",\n"
	    str=${str}${lin}
	done <<< $ip

    str="${str::-3}"'\n'"           "'}\n   },\n'
    st=${st}${str}
done

st='{\n'${st::-3}'\n}\n'
echo -ne $st> ./inventory.json
