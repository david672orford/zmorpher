#! /bin/sh
unset `locale | cut -d= -f1`
export PERL5LIB=./lib
export PERL_HASH_SEED=0
./bin/txt2adb.pl x.z.subpatch zaliz.txt >zaliz_new.adb 2>zaliz_new.adb.err
