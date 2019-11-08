#!/usr/bin/perl -w
# Copyright (C) 1999-2003  Juri Linkov <juri@jurta.org>
# Copyright (C) 2017 David Chappell
# This file is distributed under the terms of the GNU GPL.

use utf8;
use open qw(:std :utf8);
use POSIX qw(locale_h strftime);
use Encode qw(encode);
use Zaliz_Inflect;
use ADB_File;

my $DEBUG = 1;
my $CURDATE = strftime('%Y-%m-%d', localtime);
my $PROGRAM = ($0 =~ /([^\/]*)$/)[0];
my $VERSION = "0.0.1dsc";

# For debugging
use JSON;
my $json = JSON->new->canonical(1)->allow_nonref;
sub json { return $json->pretty->encode(shift) }

sub usage {
  warn "Запуск: $PROGRAM zaliz.adb zaliz2.adb zaliz2.suf zaliz2.acc [zaliz.lst]\n";
  exit(9);
}

my $adb_file_I = shift || usage();
my $adb2_file_O = shift || usage();
my $suf_file_O = shift || usage();
my $acc_file_O = shift || usage();

ADB_File::load_dictionary($adb_file_I);

open(ADB2, ">:encoding(utf8)", $adb2_file_O) or warn "Cannot open $adb2_file_O: $!\n" and exit(1);
open(SUF,  ">:encoding(utf8)", $suf_file_O) or warn "Cannot open $suf_file_O: $!\n" and exit(2);
open(ACC,  ">:encoding(utf8)", $acc_file_O) or warn "Cannot open $acc_file_O: $!\n" and exit(3);

print ADB2 "# $CURDATE $PROGRAM v$VERSION http://www.jurta.org/rus/zaliz/index.ru.html\n";

my $pns = 0;		# suffix paradigm ID counter
my $pna = 0;		# accent paradigm ID counter
my %sufs = ();		# suffix paradigm to ID map
my %accs = ();		# accent paradigm to ID map
my %pcs = ();		# suffic paradigm usage counts (by ID)
my %pca = ();		# accent paradigm usage counts (by ID)

# For each word in each list file
while(my $word = <>)
  {
  chomp $word;
  if($DEBUG)
    {
    print "================================================================\n";
    print "Word: $word\n";
    print "================================================================\n";
	print "\n";
    }

  # For each homonym listed in Zaliznyak's dictionary
  for my $article (ADB_File::get_articles($word))
    {
	print "\$article = ", json($article), "\n" if($DEBUG);

	# Produce the whole paradigmn from the dictionary article.
    # If the dictinary article give more than one method of declension
	# or conjugation, this will produce more than one whole paradigmn.
    my ($wi, $wfh) = Zaliz_Inflect::article2paradigm($article);
	if($DEBUG)
      {
	  print "\$wi = ", json($wi), "\n";			# word info
	  print "\$wfh = ", json($wfh), "\n";		# word forms hash
      }

	# Make sure the first variant has all the key/value pairs defined in any variant.
    foreach my $ph (@{$article}[1..scalar(@{$article})-1])
      {
      foreach my $key (keys %{$ph})
        {
        $article->[0]->{$key} = $ph->{$key} if !(exists $article->[0]->{$key})
        }
      }

	# Extract some of those key value pairs into %props.
    my %props = map {
      $_,$article->[0]->{$_}
      } grep {!/^(с|и|у[12]|ос[ф]?|ч[ёо23]?|ф[зпн]|искл|вар)$/} keys %{$article->[0]};

	# If the word has more than one form, write entries
    if(defined $wfh)
      {	

      # Find the invariant stem
      my $base = $wi->[0]->{'с'};		# start with headword
      map {								# trim to leave invariant stem
        map {
          if(length($_->{'с'})) {
            while($_->{'с'} !~ /^$base/) { $base =~ s/.$// }
          }
        } @{$_}
      } values(%{$wfh});

      # Save length of invarant stem to which the endings will later be pasted.
      $props{'б'} = length($base);

      # Последовательность форм зависить от части речи.
      my $part_of_speech = $wi->[0]->{'т'};
      my @forms = @{$Zaliz_Inflect::paradigms{$part_of_speech}};

      # закончания
      my $suf =
          join(";", map {
            join(",", map {
              (!(length($_->{'с'}))) ? "0" :
              ($_->{'с'} =~ /^$base(.*)/) ?
              $1.(defined $_->{'з'} ? "(".$_->{'з'}.")" : "").
                 (defined $_->{'п2'} ? "[".(($_->{'п2'} eq "1")?"в,на":($_->{'п2'}))."]" : "").
                 (defined $_->{'р2'} ? "[]" : "").
                 (defined $_->{'ф'} &&
                   ($_->{'ф'} eq "фз" && "*" || 		# форма затруднительна ("X", "!")
                    $_->{'ф'} eq "фп" && "?" ||			# форма предположительна ("-", "-")
                    $_->{'ф'} eq "фн" && "-" ||			# формы нет ("[X]", "?")
                    defined $_->{'ф'})) : $_->{'с'}
            } @{$wfh->{$_}})
          } @forms);

      # ударение
      my $acc =
          join(";", map {
            join(",", map {
              $_->{'у'}
            } @{$wfh->{$_}})
          } @forms);

      if($DEBUG) {
        print "\$suf = ", json($suf), "\n";
        print "\$acc = ", json($acc), "\n";
      }

      # Сохранить закончание
      if(!defined $sufs{$suf}) { $sufs{$suf} = ++$pns }
      $pcs{$sufs{$suf}}++;      # pcs - paradigm counter for suffixes
      $props{'ио'} = $sufs{$suf};

      # Сохранить ударение
      if(!defined $accs{$acc}) { $accs{$acc} = ++$pna }
      $pca{$accs{$acc}}++;      # pca - paradigm counter for accents
      $props{'иу'} = $accs{$acc};
      }

    # Записать законеную запись
	# Sort keys in KOI8-R order so that we can compare the result to that on the website.
    print ADB2 "с:$word", map ({
      "\t$_" . ($props{$_} ne ":" ? ":".$props{$_} : "")
      } sort({encode("koi8-r",$a) cmp encode("koi8-r",$b)} keys %props)), "\n";
    }
  }

# Sort the suffix paradigms by ID number and write them out
print SUF "# $CURDATE $PROGRAM v$VERSION http://www.jurta.org/rus/zaliz/index.ru.html\n";
map {
  print SUF "$sufs{$_}\t$pcs{$sufs{$_}}\t$_\n"
} sort {
  $pcs{$sufs{$b}} <=> $pcs{$sufs{$a}} || $sufs{$a} <=> $sufs{$b}
} (keys(%sufs));

# Sort the accent paradigms by ID number and write them out
print ACC "# $CURDATE $PROGRAM v$VERSION http://www.jurta.org/rus/zaliz/index.ru.html\n";
map {
  print ACC "$accs{$_}\t$pca{$accs{$_}}\t$_\n"
} sort {
  $pca{$accs{$b}} <=> $pca{$accs{$a}} || $accs{$a} <=> $accs{$b}
} (keys(%accs));

