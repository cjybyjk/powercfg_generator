#!/bin/bash

while read -r soctext
	do
		tmparr=(${soctext//:/ })
			soc_model="${tmparr[0]}"
			soc_name="${tmparr[1]}"
			is_big_little="${tmparr[2]}"
			cluster_0="${tmparr[3]}"
			cluster_1="${tmparr[4]}"
			if $is_big_little ; then
				cluster_num=2
			else
				cluster_num=1
			fi
			mkdir soc/$soc_name
echo "soc_name=$soc_name
soc_model=$soc_model
cluster_num=$cluster_num
cluster_0=$cluster_0" > soc/$soc_name/socinfo.sh
if $is_big_little ; then
	echo "cluster_1=$cluster_1" >> soc/$soc_name/socinfo.sh
fi


	done < ../../config/list_of_socs
