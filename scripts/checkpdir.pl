#!/usr/bin/perl

# создает каталог с текущей версией в source/<package> 
# для корректной работы патчера при сборке

use File::Path;

sub process_mk($) {
  my ($fullfile) = @_;
  my ($subdir,$file) = $fullfile =~ m|([^/]*)/([^/]*)\.mk$|;
  if (lc($file) eq lc($subdir)) {
    open my $handle, "<$fullfile";
    my $vers = undef;
    while (<$handle>) {
      next if ($_ =~ m|\s*#|);
      if ($_ =~ m|^\s*(.*?_VERS)\s*=\s*(.*?)\s*$|) {
        $vers = $2;
         last;
      }
    }
    my ($subdir) = $fullfile =~ m|^(.*?)[/]([^/]*)$|;
    unless (-d "$subdir/$vers") {
      print "no dir $subdir/$vers\n";
      mkpath "$subdir/$vers";
    }
   
#    print "$fullfile;$subdir;$file;$vers\n";
    close $handle;
  }
}

sub process_dir($) {
  my ($subdir) = @_;
  foreach (<$subdir/*>) {
    if (-d $_) {
      process_dir($_);
    } elsif ($_ =~ m|\.mk$|) {
      process_mk($_);
    }
  }
}

process_dir("source");