#!/usr/bin/perl

use File::Path;

my $skip = 0;
my $src_path = undef;
my $check_dates = 0;


do {
  my $arg = shift @ARGV;
  if ($arg =~ m|^-|) {
    $skip = shift @ARGV if ($arg eq "-skip");
    $check_dates = 1 if ($arg eq "-date");
  } else {
    $src_path = $arg;
  }
} while ($#ARGV >= 0 && !defined($src_path));

exit unless (defined($src_path));

while (<>) {
  $_ =~ s/\n|\r//g;
  if ($_ =~ m|^Двоичные файлы (.*?) и (.*?) различаются$|) {
    my $dir = 0; # 0 - from new to old
    my $newfile = 0;
    my ($old_path,$new_path) = ($1,$2);
 
    foreach (1..$skip) {
      $old_path =~ s|^.*?/||;
      $new_path =~ s|^.*?/||;
    }
    $new_path = "$src_path/$new_path";

    $dir = 1 unless (-f $new_path);
    $newfile = 1 unless (-f $old_path);
    $dir = 1 if (-A $new_path > -A $old_path && $check_dates);
    
    my $path = $old_path;
    $path =~ s|/[^/]*$||; 

    if ($dir) {
      print "$old_path -> $new_path\n";
    } else {
      print "create dir $path\n" unless (-d $path);
      mkpath $path unless (-d $path);
      print "$old_path <- $new_path\n";
      system "cat \"$new_path\" > \"$old_path\"";
      print "svn add $old_path\n" if ($newfile);
      system "svn add \"$old_path\"" if ($newfile);
    }
  }
}
