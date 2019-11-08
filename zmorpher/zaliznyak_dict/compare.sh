#! /bin/sh
REFDIR="../zmorpher_db_data_v1"
for filename in zaliz2.adb zaliz2.suf zaliz2.acc
	do
	echo "========================================="
	echo " $filename"
	echo "========================================="
	diff -u $REFDIR/$filename $filename
	done
