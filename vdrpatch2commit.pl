#!/usr/bin/perl

use strict;
use warnings;
use Net::FTP;
use Data::Dumper;
use File::Basename;
my $selfpath = dirname(__FILE__);

{#main
  # Get command FTP link from command line parameter
  my ($link) = @ARGV
    or die("Give FTP link as command line parameter!\n");

  # Split link and check protocol
  my ($proto, $host, $path) = $link =~ m#([^/]+)://([^/]+)/(.+)#
    or die("Invalid link format: $link");
  die ("Only FTP links allowed!\n") if ($proto ne "ftp");

  # Connect to FTP server
  my $ftp = Net::FTP->new($host)
    or die("Failed to connect: $@");
  $ftp->passive(1)
    or die($ftp->message);
  $ftp->login("anonymous",'-anonymous@')
    or die($ftp->message);

  # Get modification time of patch file (also checks for file existence)
  my $modtime = $ftp->mdtm($path)
    or die("Invalid path: $path\n");

  # Download patch file
  my $patchfilename = basename($path);
  $ftp->get($path, "$selfpath/$patchfilename");

  # Create commit message
  my $commitmessage = $patchfilename;
  my $comment = GetCommentFromPatch($patchfilename);
  $commitmessage .= "\n\n$comment" if ($comment);


  # Now apply patch to the files in the GIT repo
  system('patch', '-i', $patchfile);
  die("Failed to patch\n") if ($?);

  # Remove patch file
  unlink($patchfile);

  # Create commit
  system('git', 'commit', '--author=Klaus', "--date=$modtime", '-am', $commitmessage);

  # Print status to visualize if the patch created new files that still need to
  # be added into GIT control manually
  system('git', 'status');
}

# Reads "commentarea" from patch file
# Preformats patch comment for the commit message
sub GetCommentFromPatch {
  my ($patchfile) = @_;
  die() if (! -s $patchfile);

  # Read comment area.
  # Remove "#" in front of lines
  # Merge all lines into one line separated by space
  open(my $fh, '<', $patchfile) or die($!);
  my $comment = "";
  while (my $line = <$fh>) {
    chomp($line);
    last if ($line =~ /^--- /);
    $line =~ s/^# *//;
    $comment .= ' ' . $line;
  }

  # Remove leading and trailing space
  $comment =~ s/\s+$//;
  $comment =~ s/^\s+//;

  return $comment;
}
