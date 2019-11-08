#!/usr/bin/perl -w
# -*- mode: perl; coding: cyrillic-koi8; -*-
# Copyright (C) 1999-2003  Juri Linkov <juri@jurta.org>
# License: GNU GPL 2 (see the file README)

# perl txt2adb.pl z.x.subpatch zaliz.txt > zaliz.adb 2> zaliz.adb.err

use locale;
use POSIX qw(locale_h strftime);
my $CURDATE = strftime('%Y-%m-%d', localtime);
my $PROGRAM = ($0 =~ /([^\/]*)$/)[0];
my $VERSION = "0.0.1";

sub usage {
  warn "������: $PROGRAM z.x.subpatch zaliz.txt > zaliz.adb 2> zaliz.adb.err";
  exit(1);
}

# ������ ���� ����������
my $x_subpatch = shift || usage();
open(PATCH, "<$x_subpatch") || warn "���� �� ������: $@";
my $line;
while (<PATCH>) {
  chomp;
  if (/^< /) {
    $line = substr($_, 2);
    $lineh{$line} = "";
  } elsif (/^> /) {
    $lineh{$line} .= substr($_, 2)
  }
}
close(PATCH);

print <<HERE;
# -*- mode: text; coding: cyrillic-koi8; -*-
# $CURDATE $PROGRAM v$VERSION http://www.jurta.org/rus/zaliz/index.ru.html
HERE

my $vml = 0; # multi-line variants
my $sort_order = " ��� �3 �2 � ���� �� �� ���� �� �� �� �� ��� �� �� ��� ��� ��� ��� �� �� �3 �2 �� ޣ � �2� �2 �2 �2 �1 � �2� � �� � �� �2 � � � ";

while (<>) {
  next if /^#/;
  chomp;

  my (%props, %fzprops, %fnprops);
  # $o - ������������ ������ (original)
  # $w - ������� ������ (work)
  # $fp - ����� ����������������
  # $fz - ����� ��������������
  # $fn - ����� ���
  # $excp - ���������� (exception)
  my ($o, $w, $fp, $fz, $fn, $excp);
  $o = $_;

  # ��������
  if (s{(?://|=)>}{}) { $vml = 1 }
  elsif (s{<(?:=|//)}{}) { $vml++ }
  elsif ($vml) { $vml = 0 }
  if ($vml) { $props{'���'} = $vml }

  s/\s*$//;

  # ��������� ����� � �������� ���������� �����
  if (s/^([^\d]+)\s+([\d.,]+)\s+//) {
    $w = $1;
    my $acc = $2;
    $w =~ s/^�������$/�������/;
    while ($acc =~ s(,(\d+))()) { substr($w, $1-1, 1) =~ tr(�)(�) }
    $props{'�'} = $acc;
  } else { warn "������������ ������ ������: $o\n"; next }

  # �������������
  if (s/\s*%\s*(.*)$//) { $props{'��'} = $1 }
  # �������������� ����� �������
  if (!m|@.*\[//| && s|\[//([^:]*)\]||) { $props{'��'} = $1 }
  # ������ ���������������� ����
  if (s/\s*\$\s*(.*)$//) { $props{'���'} = $1 }
  # �������������� ����������� � ���������/���������
  if (s/(?:,)?\s*\#(\d+)\s*//) { $props{'��'} = $1 }
  # �������������� ������������ �����
  if (s/\s*@\s*(.*)$//) {
    my $exc = $1;
    ($exc =~ s/^(\S+):/:/) && ($_ .= "0".$1);
    if ($exc !~ /;/ && $exc =~ s/_���\. ����� �������\._//) {
      $excp = "{'��'=>[{'�'=>'$w','�'=>'$props{'�'}'}]}";
    } else {
      $excp = $lineh{$exc};
      $excp or warn "���������� �� ������� � ����� $x_subpatch: \@$exc\n";
      (defined $excp) && ($exc eq $excp) && (undef $excp, 1) &&
        warn "���������� ���������� ������ �������: \@$exc\n";
    }
  }

  # TEST
#   if (s/_������� ����\. �����\. ����\._(?:\s*\(_�����\._\)\s*(\w+)\s*)?//) {
#     warn "OK: $w:$1:$_\n"
#   }
# ����� 5 ��� 7�/�, �, _������� ����. �����. ����._ (_�����._) �������
# ����������� 9 �� 4�, _����. �����._ �������ĳ����
# ����::{'���'=>[{'�'=>'�������ģ����','�'=>9}]}

  # ���������� ��� �����
  if (s/,\s*_���������� ��� �����_(?:\s*\((?:_���_\s*)?([^)]+)\))?//) { $props{'�2�'} = ($1 or "") }
  # ����� ������������� ������ � ���������� ���������������
  if (m/:/ && (m/^[^\(\[]*:/ || !m/[\(\[][^\)\]]*:.*[\)\]]/)
     && s/\s*:\s*(.*)$//) { $props{'����'} = $1 }
  # �������� �������� (���������)
  if (s/\(_([^\)]*?)_?\)\s*// # &&$1ne"�"&&$1ne"��"   # if(s|\(([^��][^\)]*)\)||
    ) { $props{'�'} = $1 }
  # �������������� �������� �������� (���������)
  if (s/\(_([^\)]*?)_?\)\s*// # &&$1ne"�"&&$1ne"��"   # if(s|\(([^��][^\)]*)\)||
    ) { $props{'�2'} = $1 }
  # �������� � ��������� ����� (���������)
  if (s/\[_([^\]]+)\]//) { $props{'�3'} = $1 }

  s/^\s*//; s/\s*$//;

  if (s/_�\. ��\. �������\._//) { $fzprops{'��'} = "" }
  if (s/_�\. �������\._//) { $fzprops{'��'} = "" }
  if (s/_��\. �������\._//) { $fzprops{'.�'} = "" }
  if (s/_��\. �������\., ����� �\._//) { $fzprops{'[^�]�'} = "" }
  if (s/_�� � � � �������\._//) { $fzprops{'�.��'} = ""; $fzprops{'�.��'} = "" }
  if (s/_�� � �������\._//) { $fzprops{'�.��'} = "" }
  if (s/_�� � �������\._//) { $fzprops{'�.��'} = "" }
  if (s/_�� �������\. \(����� �� �\)_//) { $fzprops{'�.�[^�]'} = ""; $fzprops{'�.�'} = "" }
  if (s/_�� �������\._//) { $fzprops{'�'} = "" }
  if (s/_�� � �����\. �������\._//) { $fzprops{'�'} = ""; $fzprops{'�'} = "" }
  if (s/_�����\. �������\._//) { $fzprops{'�'} = "" }
  if (s/_�����\. �������\. ��_//) { $fzprops{'[^�]'} = "" }
  if (s/_����\. ����� �������\._//) { $fzprops{'..'} = "" }
  if (s/_�����\. �������\._//) { $fzprops{'!..'} = "" }
  if (s/_�����\. �������\._//) { $fzprops{'��'} = "" }
  if (s/_�����\. � �����\. �������\._//) { $fzprops{'��'} = ""; $fzprops{'!..'} = "" }
  if (s/_����\. 1 ��\. �������\._//) { $fzprops{'�1�'} = "" }
  if (s/_���\. 1 ��\. �������\._//) { $fzprops{'�1�'} = "" }
  if (s/_���\. ����������_//) { $fzprops{'�..'} = "" }
  if (s/_���\. � ����\. �����\. ����������_//) { $fzprops{'�..'} = ""; $fzprops{'�.�'} = "" }
  if (s/_����\. �����\. ����\. �������\._//) { $fzprops{'���'} = "" }

  if (s/_�\. ��\. ���_//) { $fnprops{'��'} = "" }
  if (s/_�� � ���_//) { $fnprops{'�.��'} = "" }
  if (s/_�� � �����\. ���_//) { $fnprops{'�'} = ""; $fnprops{'�'} = "" }
  if (s/_�� ���_//) { $fnprops{'�'} = "" }
  if (s/_�����\. ?������ ��_//) { $fnprops{'[^�]'} = "" }
  if (s/_����\. ���� ���_//) { $fnprops{'..'} = "" }
  if (s/_����� �\., ���� ���_//) { $fnprops{'[^�][^�]'} = "" }
  if (s/_����\. ����\. ���_//) { $fnprops{'���'} = "" }
  if (s/_����\. ���, ���\. ��������\._//) { $fnprops{'�'} = "" } # TODO: ���. ��������.
  if (s/_����\. ���, ������ ����� ��������\._//) { $fnprops{'�'} = "" } # TODO: ������ ����� ��������.
  if (s/_�����\. ���_//) { $fnprops{'�.�'} = "" }
  if (s/_�����\. ���_//) { $fnprops{'��'} = "" }
  if (s/_������� ������ ����\._//) { $fnprops{'[^�]'} = "" }
  if (s/_����\. 1 ��\. ���_//) { $fnprops{'�1�'} = "" }
  if (s/_� ���\. ����� ����\. � ���\. ���_//) { $fnprops{'�..'} = ""; $fnprops{'�..'} = "" }
  if (s/_���\. � ���\. ����� ���_//) { $fnprops{'�..'} = "" }
  if (s/_���\. ���_//) { $fnprops{'�..'} = "" }
  if (s/_���\. 1 ��\. ���_//) { $fnprops{'�1�'} = "" }
  if (s/_����\. �����\._ -([^-]+)-//) { $props{'���'} = ($1 or "") }
  if (s/,\s*�������\.//) { $props{'���'} = "" }
  if (s/,\s*����\.//) { $props{'���'} = "" }

  # ������������� �����
  if (s/^��\.\s*(_��_|����\.|����\.)?\s*//) {
    if (defined $1) {
      if ($1 eq "����.") { @props{'�','�','��'} = ("�", "�", "") }
      elsif ($1 eq "����.") { @props{'�','�','��'} = ("�", "�", "") }
      elsif ($1 eq "_��_") {
        if (s/^(\w\w+)\s*//) { $props{'��'} = $1 }
        else { $props{'��'} = "��" }
      }
    } else { $props{'��'} = ($1 or "") }
  }

  # �������������� ���������� �� ������������ ���������
  if (s/\[((?:"\d+")+)\]//) { my $osf = $1; $osf =~ s/\"//g; $props{'���'} = $osf }
  # ���������� �� ������������ ���������
  if (s/((?:"\d+")+)//) { my $os = $1; $os =~ s/\"//g; $props{'��'} = $os }
  # ����������� �/�
  if (s/,\s*�\s*//) { $props{'ޣ'} = "" }
  # ����������� �/�
  if (s/,\s*�\s*//) { $props{'��'} = "" }
  # 2-� ����������� �����
  if (s/,\s*[��]2\s*//) { $props{'�2'} = "" }
  # 2-� ���������� �����
  if (s/,\s*[��]2(?: ?\((��?|��)\))?\s*//) { $props{'�2'} = ($1 or "") }
  # 2-� ���������� ����� ��������������
  if (s/,\s*\[[��]2(?: ?\((��?|��)\))?\]\s*//) { $props{'�2�'} = ($1 or "") }
  # ������̣���� �����������
  if (!m/^[^*]*��\./ && s/\*\*//) { $props{'�2'} = "" }
  # ����������� ������ ������� � ��̣�
  if (!m/^[^*]*��\./ && s/\*//)   { $props{'�'} = "" }
  # ������ �����������
  if (s/\(-(.{1,2})-\)//) { $props{'�3'} = $1 }
  # ����� ��������������
  if (s/\!//) { $fz = "" }
  # ����� ���
  if (s/\?//) { $fn = "" }
  # ������������� ������� ���
  if (s/\~//) { $fnprops{'�'} = "" }
  s/,?\s*$//;
  # ����� ����������������
  if (s/\-$//) { $fp = "" }

  # '�' - ��� ���������/��������� (������), '�[12]' - ����� ��������
  if (s/0\s*$//) { $props{'�'} = "0"; }
  elsif (s|(\d{1,2})([���D�F](?:\'{1,2})?)(/[���D�F](?:\'{1,2})?)?||) {
    $props{'�'} = $1;
    my $ud1 = $2;
    if (defined $3) {
      my $ud2 = $3; $ud2 =~ s(/)();
      $ud2 =~ tr/���D�F/abcdef/; $ud2 =~ s/\'\'/2/; $ud2 =~ s/\'/1/;
      $props{'�2'} = $ud2;
    }
    $ud1 =~ tr/���D�F/abcdef/; $ud1  =~ s/\'\'/2/; $ud1  =~ s/\'/1/;
    $props{'�1'} = $ud1;
  }
  if (s/^(�?��(?:-���)?)\s*(��)?\s*//) {
    $props{'�'} = "�"; $props{'��'} = $1;
    $props{'��'} = $2 || $w =~ /�[��]$/ && "��" || "�";
  }

  s/(��-��) ��/$1/; # � ������ ���� ����.��� ������ �������

  s/,?\s*//;

  if (s|^([���])�?//\1�?,?||) {
    ($props{'�'}, $props{'�'}, $props{'�'}) = ("�", $1, "��");
  } elsif (s|^([���])(�?)//([���])(�?),?||) {
    if ($1 ne $3 && $2 eq $4) {
      @props{'�','�'} = ("�", "$1$3");
      $props{'�'} = (defined $2 && $2 ne "") && "�" || "�";
    } else { warn "$w: ������ ��� ������ ���� � ���������� ������̣�������: $o\n" }
  } elsif (s/^��-��//) {
    @props{'�','�','�','��'} = ("�", "�", "�", "�"); # � = ���.���
  } elsif (s/^([���])(�)?(?![�����])//) {
    @props{'�','�'} = ("�", $1); $props{'�'} = $2 if defined $2;
  } elsif (s/^(�|��-�|��|����\.-�)(?![�])//) {
    my $chr = $1; $chr =~ s/\.//;
    if (!defined $props{'�'}) { $props{'�'} = $chr } # � (���) - ����� ����
    else { $props{'�2'} = $chr } # ��� ���������
  } elsif (s/^(�|������\.|����\.|�����\.|����\.|����|�����\.|�����\.|����\.)//) {
    my $chr = $1; $chr =~ s/\.//; $props{'�'} = $chr; $props{'�'} = "0";
  } elsif (s/������������� ��//) {
    $props{'�'} = "��";
  }
  if (s/^ //) {
    if (s/^([���])(�)?(?![�])//) {
      if (!defined $props{'�'}) { $props{'�'} = $1 }
      else { $props{'��'} = $1 } # ����.���
      $props{'�'} = $2 if (!defined $props{'�'} && defined $2);
    } elsif (s/^(�|��-�|��|����\.-�)//) {
      my $chr = $1; $chr =~ s/\.//;
      if (!defined $props{'�'}) { $props{'�'} = $chr }
      else { $props{'�2'} = $chr } # ��� ���������
    }
  }

  s/^\s*//;

  # ����� ����������������
  if (s/^\-//) { $fp = "" }

  if (s/\((\w+)-\)// && $props{'�'} eq "�") {
    $props{'��'} = $1;
  }

  # �������������� �������� �������� (���������)
  if (s/(_��. �����( ��������)?_ \w+)//) { # TODO: (_���������� .*_)
    $props{'�2'} .= $1
  }

  s/^[\s,;]+//;

  if ($_ ne "") {
    # ���� ����� ������ �������� ��������������
    if (defined $props{'�'} && $props{'�'} eq "����") {
      # ��������� ������������ ��ң��� �� ����� ����������
      $props{'�2'} = "�";
      my $exc = "$w: $_";
      $excp = $lineh{$exc};
      $excp or warn "��������� ������������� �� ������� � ����� $x_subpatch: $exc\n";
      (defined $excp) && ($exc eq $excp) && (undef $excp, 1) &&
        warn "��������� ������������� ���������� ������ �������: \@$exc\n";
    } else {
      # �������� ��������� �����, �������������� ����� ������ � ����������� ������
      warn "$w <> $_ <> $o\n"; # next
    }
  }

  if (defined $fp) {           # ����� ����������������
    if ($props{'�'} eq "�") { $props{'��'} = "�.��" }
    elsif ($props{'�'} eq "�") { $props{'��'} = ".�" }
  }

  if (defined $fz) {           # ����� ��������������
    if ($props{'�'} eq "�") { $fzprops{'���'} = "" }
    elsif ($props{'�'} eq "�") { $fzprops{'�'} = "" }
  }

  if (defined $fn) {           # ����� ���
    if ($props{'�'} eq "�") { $fnprops{'���'} = "" }
    elsif ($props{'�'} eq "�") { $fnprops{'�.��'} = ""; $fzprops{'�'} = "" }
  }

  if (%fzprops) { $props{'��'} = "^".join("|^", sort(keys %fzprops)) }
  if (%fnprops) { $props{'��'} = "^".join("|^", sort(keys %fnprops)) }

  print "�:$w", (map {
    "\t$_" . ($props{$_} ne "" ? ":" . $props{$_} : "")
  } sort {
    index($sort_order, " $b ") <=> index($sort_order, " $a ")
    or $a cmp $b
  } keys %props),
  (defined $excp && "\t����::$excp"), "\n";
}
