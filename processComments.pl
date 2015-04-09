#!/usr/bin/perl

# This script will read from STDIN input (or you could read from a file 
# with a trivial change) and parallelize the work across X workers.
# The worker processes are handled in the process_json subroutine. 
# 
# Example of invoking 4 workers from the command line (Linux):
# script.pl 4 < reddit_json_data 
#
# Each worker also writes to a common file using non-blocking FLOCK.  In
# this example, it creates a file of all subreddits that were seen in each 
# Reddit comment.
#
# Get a sample file with reddit comments:
#
# Small file:  https://drive.google.com/file/d/0BxTexXJx0k4KNGFBUGRUUnlOX0E/view?usp=sharing 
# Larger file: https://drive.google.com/file/d/0BxTexXJx0k4KcEwzeXpSQmxEOVU/view?usp=sharing  
#
# This script can process very quickly so make sure to decompress the source files and read 
# them from RAM or an SSD drive, otherwise you will be I/O bound with more than 2 or so workers
#
# If you get an error when trying to invoke this script, you are probably lacking some
# dependencies.  If you are using Ubuntu, make sure to install build-essential:
#
# apt-get install build-essential
#
# You can install all the Perl modules at once using:
# cpan Cpanel::JSON::XS Fcntl Term::ANSIColor Time::HiRes Sys::Info
#
# On an i7-4770 CPU using 8 threads (1 parent and 7 workers), the average processing speed
# should be around 500,000 JSON objects per second.
#
# Author:  Jason Michael Baumgartner
#

use strict;
use warnings;
use Cpanel::JSON::XS;
use Fcntl qw/ :flock /;
use POSIX;
use Term::ANSIColor qw(:constants);
use Time::HiRes qw /time/;
use Sys::Info;
use Sys::Info::Constants qw( :device_cpu );

my $info = Sys::Info->new;
my $cpu  = $info->device(CPU => "count");
my $total_cores = $cpu->count;
my $total_lines_processed = 0;
my $total_lines_length = 0;
my $elapsed_time = 0;
my $begin_time = time;
my @pids;               # array to hold all child PIDS
my (@input,@output);    # arrays to hold our file handles to each worker
my $output_file = "/tmp/output.txt"; # All workers will dump their data to this location

$|=1;  # Turn off buffering on STDOUT

# Get number of worker threads as command line option 
# and default to using one worker per core leaving one core free

use constant { 	MAX_CORES => $total_cores,
		NUM_PROCS => $ARGV[0] || 7,
		};

# This loop creates the actual workers
for (1..NUM_PROCS) {
pipe($input[$_],$output[$_]);
my $pid = process_json($_); 
push(@pids, $pid);
}

# Process each line from Standard Input and rotate between forked processes
print "\n";

while (<STDIN>) {
$total_lines_length += length($_);
my $workerNumber = ($total_lines_processed % NUM_PROCS) + 1;
print {$output[$workerNumber]} $_;
$total_lines_processed++;
  unless ($total_lines_processed % 12321) {
  $elapsed_time = time - $begin_time;
  print GREEN, "Processed " . commify($total_lines_processed) . " objects.", WHITE . " [" . commify($total_lines_length) . " bytes] " . commify(floor($total_lines_processed / $elapsed_time)) . " OPS per second.\r"
  };
}
print BOLD, GREEN, "Processed " . commify($total_lines_processed) . " objects.", WHITE . " [" . commify($total_lines_length) . " bytes] " . commify(floor($total_lines_processed / $elapsed_time)) . " OPS per second.\n";

# We're done processing STDIN so now let's close the pipes to the workers
# so that they can exit gracefully

for (1..NUM_PROCS) {
close $output[$_];
}

# This is subroutine that will be forked into workers
sub process_json {
my $fileHandleNum = shift;
my $pid = fork;
return $pid if $pid;     # Off to the parent process

##################################
# We are now in the child process
#################################

close $output[$fileHandleNum]; # Close pipe that would write to parent 
my $output_string;
while (readline($input[$fileHandleNum])) {  	# Start reading data piped from parent and do something with it

  # Get reddit Data
  my $decoded_json = decode_json($_) or print $!;
  my $subreddit_id = strtol(substr($decoded_json->{subreddit_id},3),36);
  my $link_id = strtol(substr($decoded_json->{link_id},3),36);
  my $id = strtol($decoded_json->{id},36);
  my $created_utc = $decoded_json->{created_utc};
  my $score = $decoded_json->{score};
  my $gilded = $decoded_json->{gilded};
  my $parent_id = strtol(substr($decoded_json->{parent_id},3),36);

  # Create a binary file using pack (smaller size)
  # $output_string .= pack("QLLQLsc",$id,$subreddit_id,$link_id,$parent_id,$created_utc,$score,$gilded); 

  # ... or create a standard text file for fast import into a database
    $output_string .= "$id,$subreddit_id,$link_id,$parent_id,$created_utc,$score,$gilded\n";

    if (length $output_string > 1000000) {  	# To prevent thrashing from opening on every line read, let's wait till the produced output is X bytes large 
    open (my $fh, ">>", $output_file) or die "$0 [$$]: open: $!";
      if (flock $fh, LOCK_EX|LOCK_NB) {  	# Don't block for lock -- Just add to output variable until we eventually can get a lock
      print $fh $output_string      or die  "$0 [$$]: write: $!";
      close $fh               or warn "$0 [$$]: close: $!";
      $output_string = "";
      }
    }
  }
open my $fh, ">>", $output_file or die  "$0 [$$]: open: $!"; # Worker is done and the file handle was closed in the parent process -- finish the remaining writes before exiting
flock $fh, LOCK_EX or die  "$0 [$$]: flock: $!";
print $fh $output_string or die  "$0 [$$]: write: $!";
close $fh or warn "$0 [$$]: close: $!";
exit;
}

sub commify {
    my ( $sign, $int, $frac ) = ( $_[0] =~ /^([+-]?)(\d*)(.*)/ );
    my $commified = (
        scalar reverse join ',',
        unpack '(A3)*',
        scalar reverse $int
    );
    return $sign . $commified . $frac;
}
