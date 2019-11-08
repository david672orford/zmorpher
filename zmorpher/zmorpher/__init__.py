# encoding=utf-8
# zmorpher/__init__.py
# Russian Inflection using Zaliznyak's Dictionary
# Last modified: 19 October 2018
#
# Definitions of terms:
#  lexeme--a unit of grammatical meaning, often the set of a word's
#    inflectioned forms
#  lemma--that form of a lexeme which is chosen to represent it as
#    the head word in a dictionary
#

from sqlalchemy import Column, String, Integer, ForeignKey, PickleType
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import relationship, sessionmaker
from sqlalchemy import create_engine
import re
import os

# Opencorpa tag which we support
zaliz_supported_tags = (
	"NOUN", "NUMR", "ADJF", "ADJS", "COMP", "NPRO", "INFN", "VERB", "GRND", "PRTF", "PRTS", "ADVB", "INTJ", "PRED", "PREP", "CONJ", "COMP", "PRCL",
	"nomn", "gent", "datv", "accs", "ablt", "loct",		# six cases
	"inan", "anim",					# inanimate, animate
	"masc", "femn", "neut",			# gender
	"sing", "plur",					# singular and plural
	"actv", "pssv",					# active and passive participles
	"1per", "2per", "3per",
	"past", "pres", "futr", "impr",
	"impf", "perf",
	"intr", "tran",					# transitivity
	"Fixd",							# fixed form
	"V-oy",		# -ою
	"V-ey",		# -ею
	"gen2",		# genitive on -у
	"loc2",		# locative on -у
	"Af-p",		# after a preposition
	)
zaliz_supported_tags_set = frozenset(zaliz_supported_tags)

# There must be a more consise way to do this
tag_sort_order = dict()
i = 0
for tag in zaliz_supported_tags:
	tag_sort_order[tag] = i
	i += 1

# The forms (expressed as Opencorpa tag sets) for each part of speach
zaliz_tag2index = {
 ("NOUN",12)	: [
			"NOUN nomn sing", "NOUN gent sing", "NOUN datv sing", "NOUN accs sing", "NOUN ablt sing", "NOUN loct sing",	
			"NOUN nomn plur", "NOUN gent plur", "NOUN datv plur", "NOUN accs plur", "NOUN ablt plur", "NOUN loct plur",
			],
 ("NUMR",7)		: [
			"NUMR nomn sing", "NUMR gent sing", "NUMR datv sing", "NUMR accs inan sing", "NUMR accs anim sing", "NUMR ablt sing", "NUMR loct sing",	
			],
 ("ADJF",33)	: [
			"ADJF masc sing nomn", "ADJF masc sing gent", "ADJF masc sing datv", "ADJF inan masc sing accs", "ADJF anim masc sing accs", "ADJF masc sing ablt", "ADJF masc sing loct",
			"ADJF femn sing nomn", "ADJF femn sing gent", "ADJF femn sing datv", "ADJF femn sing accs", "ADJF anim femn sing accs", "ADJF femn sing ablt", "ADJF femn sing loct",
			"ADJF neut sing nomn", "ADJF neut sing gent", "ADJF neut sing datv", "ADJF neut sing accs", "ADJF anim neut sing accs", "ADJF neut sing ablt", "ADJF neut sing loct",
			"ADJF plur nomn", "ADJF plur gent", "ADJF plur datv", "ADJF inan plur accs", "ADJF anim plur accs", "ADJF plur ablt", "ADJF plur loct",
			"ADJS masc sing", "ADJS femn sing", "ADJS neut sing", "ADJS plur",
			"COMP",
			],
 ("NPRO",6)		: [
			"NPRO nomn", "NPRO gent", "NPRO datv", "NPRO accs", "NPRO ablt", "NPRO loct",
			],
 ("ADJF",28)	: [		# adjectival pronouns
			"ADJF masc sing nomn", "ADJF masc sing gent", "ADJF masc sing datv", "ADJF inan masc sing accs", "ADJF anim masc sing accs", "ADJF masc sing ablt", "ADJF masc sing loct",
			"ADJF femn sing nomn", "ADJF femn sing gent", "ADJF femn sing datv", "ADJF femn sing accs", "ADJF anim femn sing accs", "ADJF femn sing ablt", "ADJF femn sing loct",
			"ADJF neut sing nomn", "ADJF neut sing gent", "ADJF neut sing datv", "ADJF neut sing accs", "ADJF anim neut sing accs", "ADJF neut sing ablt", "ADJF neut sing loct",
			"ADJF plur nomn", "ADJF plur gent", "ADJF plur datv", "ADJF inan plur accs", "ADJF anim plur accs", "ADJF plur ablt", "ADJF plur loct",
			],
 ("INFN",149)	: [
			"INFN",
			"VERB past masc sing", "VERB past femn sing", "VERB past neut sing", "VERB past plur",
			"VERB pres 1per sing", "VERB pres 2per sing", "VERB pres 3per sing", "VERB pres 1per plur", "VERB pres 2per plur", "VERB pres 3per plur",
			"VERB futr 1per sing", "VERB futr 2per sing", "VERB futr 3per sing", "VERB futr 1per plur", "VERB futr 2per plur", "VERB futr 3per plur",
			"VERB sing impr", "VERB plur impr",
			"GRND pres", "GRND past",	
			"PRTF pres actv sing masc nomn",
			"PRTF pres actv sing masc gent",
			"PRTF pres actv sing masc datv",
			"PRTF pres actv sing masc inan accs",
			"PRTF pres actv sing masc anim accs",
			"PRTF pres actv sing masc ablt",
			"PRTF pres actv sing masc loct",
			"PRTF pres actv sing femn nomn",
			"PRTF pres actv sing femn gent",
			"PRTF pres actv sing femn datv",
			"PRTF pres actv sing femn inan accs",
			"PRTF pres actv sing femn anim accs",
			"PRTF pres actv sing femn ablt",
			"PRTF pres actv sing femn loct",
			"PRTF pres actv sing neut nomn",
			"PRTF pres actv sing neut gent",
			"PRTF pres actv sing neut datv",
			"PRTF pres actv sing neut inan accs",
			"PRTF pres actv sing neut anim accs",
			"PRTF pres actv sing neut ablt",
			"PRTF pres actv sing neut loct",
			"PRTF pres actv plur nomn",
			"PRTF pres actv plur gent",
			"PRTF pres actv plur datv",
			"PRTF pres actv plur inan accs",
			"PRTF pres actv plur anim accs",
			"PRTF pres actv plur ablt",
			"PRTF pres actv plur loct",
			"PRTS pres actv sing masc",
			"PRTS pres actv sing femn",
			"PRTS pres actv sing neut",
			"PRTS pres actv plur",
			"PRTF past actv sing masc nomn",
			"PRTF past actv sing masc gent",
			"PRTF past actv sing masc datv",
			"PRTF past actv sing masc inan accs",
			"PRTF past actv sing masc anim accs",
			"PRTF past actv sing masc ablt",
			"PRTF past actv sing masc loct",
			"PRTF past actv sing femn nomn",
			"PRTF past actv sing femn gent",
			"PRTF past actv sing femn datv",
			"PRTF past actv sing femn inan accs",
			"PRTF past actv sing femn anim accs",
			"PRTF past actv sing femn ablt",
			"PRTF past actv sing femn loct",
			"PRTF past actv sing neut nomn",
			"PRTF past actv sing neut gent",
			"PRTF past actv sing neut datv",
			"PRTF past actv sing neut inan accs",
			"PRTF past actv sing neut anim accs",
			"PRTF past actv sing neut ablt",
			"PRTF past actv sing neut loct",
			"PRTF past actv plur nomn",
			"PRTF past actv plur gent",
			"PRTF past actv plur datv",
			"PRTF past actv plur inan accs",
			"PRTF past actv plur anim accs",
			"PRTF past actv plur ablt",
			"PRTF past actv plur loct",
			"PRTS past actv sing masc",
			"PRTS past actv sing femn",
			"PRTS past actv sing neut",
			"PRTS past actv plur",
			"PRTF pres pssv sing masc nomn",
			"PRTF pres pssv sing masc gent",
			"PRTF pres pssv sing masc datv",
			"PRTF pres pssv sing masc inan accs",
			"PRTF pres pssv sing masc anim accs",
			"PRTF pres pssv sing masc ablt",
			"PRTF pres pssv sing masc loct",
			"PRTF pres pssv sing femn nomn",
			"PRTF pres pssv sing femn gent",
			"PRTF pres pssv sing femn datv",
			"PRTF pres pssv sing femn inan accs",
			"PRTF pres pssv sing femn anim accs",
			"PRTF pres pssv sing femn ablt",
			"PRTF pres pssv sing femn loct",
			"PRTF pres pssv sing neut nomn",
			"PRTF pres pssv sing neut gent",
			"PRTF pres pssv sing neut datv",
			"PRTF pres pssv sing neut inan accs",
			"PRTF pres pssv sing neut anim accs",
			"PRTF pres pssv sing neut ablt",
			"PRTF pres pssv sing neut loct",
			"PRTF pres pssv plur nomn",
			"PRTF pres pssv plur gent",
			"PRTF pres pssv plur datv",
			"PRTF pres pssv plur inan accs",
			"PRTF pres pssv plur anim accs",
			"PRTF pres pssv plur ablt",
			"PRTF pres pssv plur loct",
			"PRTS pres pssv sing masc",
			"PRTS pres pssv sing femn",
			"PRTS pres pssv sing neut",
			"PRTS pres pssv plur",
			"PRTF past pssv sing masc nomn",
			"PRTF past pssv sing masc gent",
			"PRTF past pssv sing masc datv",
			"PRTF past pssv sing masc inan accs",
			"PRTF past pssv sing masc anim accs",
			"PRTF past pssv sing masc ablt",
			"PRTF past pssv sing masc loct",
			"PRTF past pssv sing femn nomn",
			"PRTF past pssv sing femn gent",
			"PRTF past pssv sing femn datv",
			"PRTF past pssv sing femn inan accs",
			"PRTF past pssv sing femn anim accs",
			"PRTF past pssv sing femn ablt",
			"PRTF past pssv sing femn loct",
			"PRTF past pssv sing neut nomn",
			"PRTF past pssv sing neut gent",
			"PRTF past pssv sing neut datv",
			"PRTF past pssv sing neut inan accs",
			"PRTF past pssv sing neut anim accs",
			"PRTF past pssv sing neut ablt",
			"PRTF past pssv sing neut loct",
			"PRTF past pssv plur nomn",
			"PRTF past pssv plur gent",
			"PRTF past pssv plur datv",
			"PRTF past pssv plur inan accs",
			"PRTF past pssv plur anim accs",
			"PRTF past pssv plur ablt",
			"PRTF past pssv plur loct",
			"PRTS past pssv sing masc",
			"PRTS past pssv sing femn",
			"PRTS past pssv sing neut",
			"PRTS past pssv plur",
			],
}

# For convenience we have expressed the Opencorpa tag sets as a space-separated
# list. Now we convert them to Python sets.
for pos in zaliz_tag2index.values():
	for i in range(len(pos)):
		pos[i] = frozenset(pos[i].split(" "))
		assert pos[i] < zaliz_supported_tags_set, "bad tag: %s" % str(pos[i])

# We keep the morphological tables in a Sqlite database thru SQLAlchemy
Base = declarative_base()
dict_filename = "zaliznyak_dict.db"
engine = create_engine('sqlite:///%s/%s' % (os.path.dirname(__file__), dict_filename))
Base.metadata.bind = engine
DBSession = sessionmaker(engine)
session = DBSession()

class zMorpher(object):
	def __init__(self):
		self.stem_cache = {}
		self.word_cache = {}

	def parse(self, word):
		"""Given a word form, find the words it could be. Return a list of Parse objects."""

		parses = []					# result goes here

		word_lower = word.lower()
		yo = "ё" if "ё" in word_lower else "е"

		# Walk down the word trying stems of growing length
		for i in range(len(word)+1):
			word_stem = word_lower[:i]
			word_ending = word_lower[i:]

			# Find all the lexmes with this stem.
			if word_stem in self.stem_cache:
				results = self.stem_cache[word_stem]
			else:
				results = session.query(zMorpherDbLexeme).filter_by(stem=word_stem).all()

				# If the word is capitalized in the text and not found in lower case, try again in upper case.
				if len(results) == 0 and word_lower != word:
					results = session.query(zMorpherDbLexeme).filter_by(stem=word[:i]).all()

				self.stem_cache[word_stem] = results

			# Now winnow the lexemes down to those with a matching ending.
			for lexeme in results:
				#print("%s %s" % (lexeme.word, lexeme.paradigm_id))

				# Non-inflected words: whole thing must match.
				if lexeme.paradigm_id is None:
					if(lexeme.lemma.replace("ё",yo).lower() == word_lower):
						parses.append(Parse(word, lexeme))

				# Inflected words: Stem together one one of the possible suffixes must match.
				else:
					suffix_i = 0
					for suffix_set in lexeme.paradigm.suffixes:
						suffix_var_i = 0
						for suffix in suffix_set:
							if suffix.replace("ё",yo) == word_ending:
								# We have a match!
								#print("%s + %s" % (word_stem, suffix))

								# Create a result object describing this wordform of this lexeme.
								parses.append(Parse(word, lexeme, (suffix_i, suffix_var_i)))

							suffix_var_i += 1
						suffix_i += 1

		# We think your word is one of these.
		return parses

	def stress_text(self, text, all=False):
		"""Add stress marks to a string, where possible, on a simplisitic word-by-word basis."""
		result = ""
		for m in re.findall(r'([\W-]*)([\w-]+)([\W-]*)', text, re.DOTALL):
			word = m[1]
			if re.match(r'^[а-яА-Я-]+$', word):		# Russian letters and hyphen
				if word in self.word_cache:
					word = self.word_cache[word]
				else:
					possibilities = set()
					for parse in self.parse(word):
						possibilities.add(parse.stressed(all))
					if len(possibilities) == 1:
						word = possibilities.pop()
					self.word_cache[m[1]] = word
			result += ("%s%s%s" % (m[0], word, m[2]))
		return result

class OpencorpaTag(frozenset):
	def __str__(self):
		return " ".join(sorted(self, key=lambda item: tag_sort_order[item]))
	def __contains__(self, tag):
		return tag <= self
	def _extract(self, possible_tags):
		tag = self.intersection(possible_tags)
		assert len(tag) == 1
		return list(tag)[0]
	@property
	def POS(self):
		return self._extract({"NOUN", "NUMR", "ADJF", "ADJS", "COMP", "NPRO", "INFN", "VERB", "GRND", "PRTF", "PRTS", "ADVB", "INTJ", "PRED", "PREP", "CONJ", "COMP", "PRCL"})
	@property
	def case(self):
		return self._extract({"nomn", "gent", "datv", "accs", "ablt", "loct", "gen2", "loc2"})
	@property
	def number(self):
		return self._extract({"sing", "plur"})
	@property
	def gender(self):
		return self._extract({"masc", "femn", "neut"})

# Adapter for compatibility with the Pymorphy2 API
# Represents a word form and provides access to the other forms
class Parse(object):
	def __init__(self, word, lexeme, form_index=None):
		self.word = word
		self._lexeme = lexeme				# zMorpherDbLexeme object: dictionary article
		self._form_index = form_index		# list: (wordform index, variant index)

	def __str__(self):
		"""String representation of a Parse object, for debugging"""
		return "<Parse word='%s' tag=%s normal_form='%s' _lexeme.id=%d _form_index=%s>" % (self.word, str(self.tag), self.normal_form, self._lexeme.id, str(self._form_index))

	@property
	def tag(self):
		"""The tags which identify this form of the word. (Singular to match Pymorphy2 API)"""
		return self._lexeme.get_form_tags(self._form_index)

	@property
	def normal_form(self):
		"""The dictionary form of this word"""
		return self._lexeme.lemma

	@property
	def lexeme(self):
		"""All the forms"""
		for form_index in self._lexeme.get_form_indexes():
			yield Parse(self._lexeme.get_form(form_index), self._lexeme, form_index)

	@property
	def normalized(self):
		"""Another Parse object which represents the dictionary form of this word"""
		return Parse(self._lexeme.lemma, self._lexeme, (0,0) if self._form_index is not None else None)

	def inflect(self, tags):
		"""Change to form represented by tags"""
		form, form_index = self._lexeme.inflect(tags)
		if form is not None:
			return Parse(form, self._lexeme, form_index)
		return None

	# Not part of Pymorphy2 API
	@property
	def definition(self):
		return self._lexeme.definition

	# Not part of Pymorphy2 API
	def stressed(self, all=False):
		"""This form of the word as a Unicode string with stress marked"""

		# Generate word in proper form, possibly with ё, and a list of the stress positions.
		stressed_form, stresses = self._lexeme.get_form_stressed(self._form_index)
		#print("stressed_form:", stressed_form)
		#print("stresses:", stresses)

		# So as to preserve capitilization we apply the stress marks to the
		# original word using stressed_form as a guide.
		result = self.word

		# Transfer ё to the original word.
		for i, ltr in enumerate(stressed_form):
			#print(i, ltr)
			if ltr == "ё":
				if result[i] == "е":
					result = result[0:i] + "ё" + result[i+1:]
				elif result[i] == "Е":
					result = result[0:i] + "Ё" + result[i+1:]

		# If we know where the stresses go and there are two or more places
		# where they could go (two or more vowels), add stress marks.
		if stresses and (all or re.search(u'[аэыуояеиёю].*[аэыуояеиёю]', result, re.IGNORECASE)):
			for stressed_letter in stresses:
				if result[stressed_letter-1] != u"ё":
					result = result[0:stressed_letter] + u"\u0301" + result[stressed_letter:]

		return result

# A word with information about inflection and stress pattern
class zMorpherDbLexeme(Base):
	__tablename__ = 'lexemes'
	id = Column(Integer, primary_key=True)
	lemma = Column(String)
	stem = Column(String, index=True)
	pos = Column(String)			# part of speech
	stresses = Column(PickleType)
	base_len = Column(Integer)
	paradigm_id = Column(Integer, ForeignKey('paradigms.id'))
	paradigm = relationship('zMorpherDbSuffixParadigm')
	stress_paradigm_id = Column(Integer, ForeignKey('stress_paradigms.id'))
	stress_paradigm = relationship('zMorpherDbStressParadigm')
	tag = Column(PickleType)
	definition = Column(String)
	phrases = Column(String)

	def __str__(self):
		return "<zMorpherDbLexeme id=%d word=%s paradigm_id=%s stress_paradigm_id=%s pos=%s tag=%s definition=%s phrases=%s>" % (self.id, self.lemma, str(self.paradigm_id), str(self.stress_paradigm_id), self.pos, self.tag, self.definition, self.phrases)

	def inflect(self, required_tags):
		"""Create the form of the word indicated by required_tags"""

		# If word is not inflected, return its only form.
		if self.paradigm_id is None:
			return Parse(self.word, self)

		# Drop tags which we do not support.
		required_tags = set(required_tags & zaliz_supported_tags_set)

		# Drop gender and person tags for pronouns since they are redundant.
		if self.pos == "NPRO":
			required_tags = required_tags - set(["1per", "2per", "3per", "masc", "femn", "neut", "sing", "plur"])

		# Pull out tags which specify variants while making a note that
		# we should return the alternative form.
		form_var_index = 0
		for variant in (
				"V-oy",		# -ою
				"V-ey",		# -ею
				"gen2",		# genitive on -у
				"loc2",		# locative on -у
				"Af-p",		# after a preposition (such as него)
			):
			if variant in required_tags:
				form_var_index = 1
				required_tags = required_tags - set([variant])
				if variant == "gen2":
					required_tags.add("gent")
				elif variant == "loc2":
					required_tags.add("loct")

		# Load the list of tags cooresponding to each ending.
		# (The list is different for each part of speach.)
		pos_paradigm_tag_sets = zaliz_tag2index.get((self.pos, len(self.paradigm.suffixes) if self.paradigm else None))
		assert len(pos_paradigm_tag_sets) == len(self.paradigm.suffixes)

		# Search for the form with the required_tags. Remember its index.
		form_index = None
		i = 0
		for wordform_tag in pos_paradigm_tag_sets:
			if required_tags <= (self.tag | wordform_tag):
				form_index = i
				break
			i += 1
		if form_index is None:
			return None

		# Apply the suffix to the base and return the result and the stress position.
		try:
			suffix = self.paradigm.suffixes[form_index][form_var_index]
		except IndexError as e:
			raise AssertionError("form_index=%d, form_var_index=%d suffixes=%s" % (form_index, form_var_index, self.paradigm.suffixes))
		if suffix == "0":			# so-called zero ending
			form = self.lemma
		else:
			form = self.lemma[:self.base_len] + suffix

		return (form, (form_index, form_var_index))

	def get_form_indexes(self):
		for i in range(len(self.paradigm.suffixes)):
			yield (i,0)

	def get_form(self, form_index):
		if self.paradigm_id is None:
			return self.lemma
		else:
			return self.lemma[:self.base_len] + self.paradigm.suffix(form_index)

	def get_form_tags(self, form_index):
		if self.paradigm_id is None:			# word is not inflected
			return OpencorpaTag({self.pos} | self.tag)
		else:									# word is inflected
			form_index, form_var_index = form_index
			tags = zaliz_tag2index[(self.pos, len(self.paradigm.suffixes))][form_index]
			# FIXME: tags not adjusted for alternative forms
			return OpencorpaTag(self.tag | tags)

	def get_form_stressed(self, form_index):
		if self.paradigm_id is None:
			stressed_form = self.lemma
			stresses = self.stresses
		else:
			stressed_form = self.lemma[:self.base_len] + self.paradigm.suffix(form_index)
			stresses = self.stress_paradigm.stresses(form_index)
		return (stressed_form, stresses)

class zMorpherDbSuffixParadigm(Base):
	__tablename__ = 'paradigms'
	id = Column(Integer, primary_key=True)
	suffixes = Column(PickleType)
	def __str__(self):
		return "<zMorpherDbSuffixParadigm %d: %s>" % (self.id, str(self.suffixes))
	def suffix(self, index):
		return self.suffixes[index[0]][index[1]]

class zMorpherDbStressParadigm(Base):
	__tablename__ = 'stress_paradigms'
	id = Column(Integer, primary_key=True)
	places = Column(PickleType)
	def __str__(self):
		return "<zMorpherDbStressParadigm %d: %s>" % (self.id, str(self.places))
	def stresses(self, index):
		place = self.places[index[0]][index[1]]
		return place

