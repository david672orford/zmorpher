# Copyright (c) 2000  Juri Linkov <juri@eta.org>
# This file is distributed under the terms of the GNU GPL.

use utf8;
package ADB_File;

my $varkey = 'вар';

# Zalizyak's dictionary
%dictionary_articles = ();

# Load the articles from Zalizyak's dictionary and index them
# by headword.
sub load_dictionary
  {
  my $adb_file = shift or die "$0: specify database file name: $!\n";
  open(ADBF, "<:encoding(utf8)", $adb_file) or die "$0: cannot open $adb_file: $!\n";
  while(<ADBF>)
    {
    chomp;
    next if /^#/;			# drop comments
    my ($word) = /^с:(\S+)/g;
    warn "Incorrect format: $_\n" and next if !$word;
	$dictionary_articles{$word} = [] unless(defined $dictionary_articles{$word});
    push(@{$dictionary_articles{$word}}, $_);
    }
  close (ADBF) || die $!;
  }

## get_article($word) -- return hash of word properties
# Load an article from Zalizyak's dictionary
sub get_articles
  {
  my $word = shift;
  make_variants(map {parse_article($_)} @{$dictionary_articles{$word}})
  }

## make_variants(@wfs) -- split words with variants into different groups
#  return array of pointers to arrays of pointers to hashes
sub make_variants
  {
  my @wis = @_;
  my $v = -1;
  my (@cres, @res);
  for my $wi (@wis)
    {
    my $vi = $wi->{$varkey};
    if(@cres && !(defined $vi && $vi == $v + 1))
      {
      push @res, [@cres];
      @cres = ();
      }
    if(defined $vi)
      { $v = $vi }
	else
      { $v = -1 }
    push @cres, $wi
    }
  if (@cres) { push @res, [@cres] }
  @res
  }

=item parse_article

Parse a Zaliznyak dictionary article

Convert string of key-value pairs separated by tabs to Perl hash

if key has no value, then assigned it ":"
if key and value are separated by colon, than value is assigned as string
if key and value are separated by two colons, than value is evaluated
Example: input:  "key1	key2:value2	key3::{a=>[b,c]}"
         output: {key1=>":", key2=>"value2", key3=>{a=>[b,c]}}

=cut

sub parse_article {
  my %wi;
  foreach (split(/\t/, shift)) {
    if (m(::?)o) {
      $wi{$`} = length($&)-2 && $' || eval $';
      warn "$@ in \"$'\"" if $@;
    } else {
      $wi{$_} = ":"
    }
  }
  \%wi
}

1;
