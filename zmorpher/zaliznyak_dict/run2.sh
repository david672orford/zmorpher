#! /bin/sh
unset `locale | cut -d= -f1`
export PERL5LIB=./lib
export PERL_HASH_SEED=0		# for repeatability

# Short test
#./bin/adb2suf.pl dicts/zaliz_yurta.adb zaliz2.adb zaliz2.suf zaliz2.acc zaliz_test.lst

# Regression Test
# Should produce same output as original, only in UTF-8
#./bin/adb2suf.pl dicts/zaliz_yurta.adb zaliz2.adb zaliz2.suf zaliz2.acc dicts/zaliz_yurta.lst

# Full run
cat dicts/zaliz_yurta.adb dicts/zaliz_dsc.adb >zaliz.adb
cat dicts/zaliz_yurta.lst dicts/zaliz_dsc.lst >zaliz.lst
./bin/adb2suf.pl zaliz.adb zaliz2.adb zaliz2.suf zaliz2.acc zaliz.lst

