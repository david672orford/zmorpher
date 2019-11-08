== Russian Inflector from Jurta.org ==

This Russian inflector was posted to the blog Jurta in the article:

  Построение полных парадигм слов русского
  языка на базе грамматического словаря

== Subdirectory "original" ==

This directory contains the original data and program files from:

  http://www.jurta.org/ru/nlp/rus/zaliz

Unmodified original files from Jurta.org:

  zaliz.adb
    This is an intermediate file produced by running zaliz.txt through
	txt2adb.pl.
  zaliz2.adb, zaliz2.suf, zaliz2.acc
    These are the final product. The adb file lists the words and refers
	to the suffixes in the suf file and the stress patterns in the acc file.
    Note that these files are dated 2007 and do not reflect the bug fix
    which Juri refers to in his answer of 23 August 2013 to a comment
	on his blog posting.
  txt2adb.pl
    Converts zaliz.txt to zaliz.adb
  adb2suf.pl
    Takes zaliz.adb and zaliz.lst as input, produces zaliz2.adb, zaliz2.suf, zaliz2.acc.
  ADB_File.pm
    Routines for loading zaliz.adb and pulling entries out of it
  Lingua-RU-Zaliz-Inflect.pm
    Implementation of the inflection rules described in the introductory
    pages of Zaliznyak's dictionary
  Lingua-RU-Accent.pm
    Implementation of the stress shift rules described in the introductory
    pages of Zaliznyak's dictionary

All the above files are in the KOI8-R encoding. 

== Subdirectory "original_runable" == 

The Perl source code files in this directory have been patched to run properly
on modern versions of Perl 5. The library files have been arranged in a
subdirectory so that the use statements will work.

Both the Perl source files and the data files remain in the KOI8-R encoding.
Set this in your .vimrc:

 set fileencodings=koi8-r,utf-8

Reconstructed data files:

  zaliz.txt
    This file is missing from the website. From the scripts we learned
    that it contains the word entries from Zaliznyak's dictionary. The
	file here is our attempted reconstruction.
  x.z.subpatch
	This file is also missing from the website. We have extracted its proper
	contents from zaliz.adb.
  zaliz.lst
    This file is also missing from the website. It is a list of all if the
    words. It can be reproduced using the command:
    $ cut -f1 zaliz2.adb | cut -c3- | LC_COLLATE=C uniq >zaliz.lst

The run1.sh script sets up the proper environment and processes zaliz.txt and
z.x.subpatch to produce zaliz.adb.

The run2.sh script sets up the proper environment and processes zaliz.adb
and zaliz.lst to produce zaliz2.adb, zaliz2.suf, and zaliz2.acc. In the
interests of reproducibility the randomization of Perl hash keys has been
disabled.

The files produced by run2.sh are somewhat different from those on the website.
This is because the code on the website has had bugs fixed (as described in
the comments, but the output files on the site have not been updated.

== Documentation ==

The documentation of the file formats is very hard to read because it is
arranged in tables without visible borders. Thus, the entries tend to run
together. The reader must parse the text in order to separate them. Therefor I
have downloaded the page, extracted that part, and added table cell borders.
The result is in:

  docs_cleaned.html

The first few tables in these instrutions describe zaliz.adb, though some
of the information is carried over into zaliz2.adb.

