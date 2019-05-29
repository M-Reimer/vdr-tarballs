#!/usr/bin/perl

use strict;
use warnings;
use LWP;
use File::Basename;

{#main
  # Get FTP/HTTP link from command line parameter
  my ($link) = @ARGV
    or die("Give FTP/HTTP link as command line parameter!\n");

  # Connect to FTP/HTTP server
  my $browser = LWP::UserAgent->new;
  my $response = $browser->get($link);
  die("Failed to load $link " . $response->status_line)
    unless($response->is_success);

  # Get modification time of patch file
  my $modtime = $response->last_modified;

  # Save patch file
  my $patchfilename = basename($link);
  open(my $fh, '>', $patchfilename) or die($!);
  print $fh $response->content;
  close($fh);

  # Create commit message
  my $commitmessage = $patchfilename;
  my $comment = GetCommentFromPatch($patchfilename);
  $commitmessage .= "\n\n$comment" if ($comment);


  # Now apply patch to the files in the GIT repo
  system('patch', '-i', $patchfilename);
  die("Failed to patch\n") if ($?);

  # Remove patch file
  unlink($patchfilename);

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
    # First line of actual patch info found
    last if ($line =~ /^--- /);
    # Sometimes the used "diff" command is the last line in the comment area
    last if ($line =~ /^diff /);
    $line =~ s/^# *//;
    $comment .= ' ' . $line;
  }

  # Remove leading and trailing space
  $comment =~ s/\s+$//;
  $comment =~ s/^\s+//;

  return $comment;
}
