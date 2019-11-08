# -*- mode: perl; coding: cyrillic-koi8; -*-
# Copyright (C) 2000-2014  Juri Linkov <juri@jurta.org>
# License: GNU GPL 2 (see the file README)
# Version: 0.1.0

package Lingua::RU::Accent;

my $vowel = "¡≈£…œ’Ÿ‹¿—";

sub accent {
  my $word = shift;
  my $acc = shift;
  my $acctype = shift;          # 0 or 1 or a or u

  return $word if $acc eq "0";
  return $word if $word !~ /[$vowel].*[$vowel]/; # TODO: should be optional

  while ($acc =~ s(,(\d+))()) {
    substr($word,$1-1,1) =~ tr(≈)(£);
  }

  if ($acctype eq "0" or $acctype eq "1") {
#      ($a, @accents) = ($acc =~ /(\d+)/g);
#      if (substr($word,$a-1,1) ne "£") { substr($word,$a-$acctype,0) = "'"; }
#      foreach $a (@accents) { substr($word,$a-$acctype,0) = "`"; }
    @accents = ($acc =~ /(\d+)/g);
    for ($i = 0; $i <= $#accents; $i++) {
      next if ($i==0 && substr($word,$accents[$i]-1,1) eq "£");
      substr($word,$accents[$i]-$acctype,0) = ($i==0) ? "'" : "`";
    }
  } elsif ($acctype eq "a") {
    while ($acc =~ /(\d+)/g) {
      (length($word) >= $1) && (substr($word,$1-1,1) =~ tr/¡≈£…œ’Ÿ‹¿—/àäçèëñöúû /)
    }
  } elsif ($acctype eq "u") {
    while ($acc =~ /(\d+)/g) {
      (length($word) >= $1) && (substr($word,$1-1,1) =~ tr(¡≈£…œ’Ÿ‹¿—)(·Â≥ÈÔı˘¸‡Ò))
    }
  }
  $word
}

# raccent - reversed accent

sub raccent {
  my $word = shift;
  my $acc = "0";         # by default
  my $acctype = shift;   # 0 or 1 or a or u
  my $rword = reverse $word;

  return $word unless $acctype eq "u"; # TODO: $acctype = 0 or 1 or a

  if (($word !~ m([·Â≥£ÈÔı˘¸‡Ò])) && ($word =~ m([¡≈£…œ’Ÿ‹¿—]))) {
    return length($`) + 1
  }

  while ($rword =~ m([·Â≥£ÈÔı˘¸‡Ò])g) {
    my $accn = length($word) - length($`);
    $acc .= "." . $accn;
    substr($word,$accn-1,1) =~ tr(·Â≥ÈÔı˘¸‡Ò)(¡≈£…œ’Ÿ‹¿—);
  }
  $rword = reverse $word;
  while ($rword =~ m(£)g) {
    my $accn = length($word) - length($`);
    $acc .= "," . $accn;
    substr($word,$accn-1,1) =~ tr(£)(≈);
  }
  $acc =~ s(^0?\.)();
  $acc
}

sub get_accent_letters {
  my $word = shift;
  my $acc = shift;
  my @retacc = ();

  return if $acc eq "0";

  while ($acc =~ s(,(\d+))()) {
    substr($word,$1-1,1) =~ tr/≈/£/;
  }
  while ($acc =~ m((\d+))g) {
    push @retacc, substr($word,$1-1,1);
  }
  @retacc;
}

# isplit returns array of beginning positions of splitted fields
sub isplit {
  my $pattern = shift;
  my $expr = shift;
  my @res;
  while ($expr =~ /$pattern/g) { push @res, length($`)+length($&); }
  @res
}

1;
