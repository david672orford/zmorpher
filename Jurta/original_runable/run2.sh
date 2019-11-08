#! /bin/sh
unset `locale | cut -d= -f1`
export PERL5LIB=./lib
export PERL_HASH_SEED=0		# for repeatability
./bin/adb2suf.pl zaliz.adb zaliz2.suf zaliz2.acc zaliz.lst >zaliz2.adb
#./bin/adb2suf.pl zaliz.adb zaliz2.suf zaliz2.acc zaliz_test.lst >zaliz2.adb
