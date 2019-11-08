zMorpher is an implementation of Russian declension and conjugation. It is
based on Zaliznyak's famous dictionary _Грамматический словарь русского языка_.

Description of dictionary entries:

  http://odict.ru/pomety/

* zaliznyak\_dict--a modified version of the Yurta code which we use to build the paradigm.
Note that while the original processes files in the KOI8 encoding, this version uses UTF-8.
* zaliznyak\_dict_v1--The output of the original Yurta code converted to UTF-8 for
comparison purposes
* bin/pymorphy2-lookup--Look up a word using Pymorphy2 for comparison purposes
* bin/zmorpher-dict-loader--read the full paradigm from zaliznyak\_dict and store it in a
Sqlite database
* zmorpher--Python library for performing lookups in the Sqlite database
* bin/zmorpher-lookup--Use the Python library above to look up a word and display the result
* bin/zmorpher-filter--Read stdin, break it into words, look them up using the Python library
above, and print the text with stress marks added to stdout

