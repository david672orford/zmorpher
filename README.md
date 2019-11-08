This is an implementation of Russian inflection including the determination
of stress.

The Jurta directory contains code to produce the entire paradigm from an 
electronic version of Andrey Zalizniak's *Грамматический словарь русского
языка*.

The zmorpher directory contains a modified copy of this code, a Python program
to load the paradigm it produces into a Sqlite database, and a Python library
for looking up words in it.

Example command:

    ./zmorpher/bin/zmorpher-filter <test_texts/"Маша и медведь.txt"

Limitations of this implementation include:

* The dictionary does not contain proper names
* It cannot analyse context, so it cannot resolve ambiguity and will
  mishandle cases where an ajoining word in the phrase steals the stress

