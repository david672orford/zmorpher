#! /bin/sh
#unset `locale | cut -d= -f1`
./bin/txt2adb.pl dicts/zaliz_dsc.txt | sort >dicts/zaliz_dsc.adb

