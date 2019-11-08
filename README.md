This is an implementation of Russian inflection including the determination
of stress.

The Jurta directory contains code to produce the entire paradigm from an 
electronic version of Andrey Zalizniak's *Грамматический словарь русского
языка*.

The zmorpher directory contains:
# A modified copy of the Jurta code
# A Python program to load the paradigm it produces into a Sqlite database
# A Python library for looking up words in the Sqlite database
# A few simple programs to demonstrate the library

Example command:

    ./zmorpher/bin/zmorpher-filter <test_texts/"Маша и медведь.txt"

Limitations of this implementation include:

* The dictionary does not contain proper names
* It cannot analyse context, so it cannot resolve ambiguity and will
  mishandle cases where an ajoining word in the phrase steals the stress

