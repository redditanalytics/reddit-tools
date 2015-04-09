# reddit-tools
Collection of tools to process data from Reddit

## processComments.pl
This is a Perl script that enables processing comment JSON objects.  You can find sample data for this 
script at the following locations:

Small file (130M):  https://drive.google.com/uc?export=download&id=0BxTexXJx0k4KNGFBUGRUUnlOX0E 

Larger file (1.2G): https://drive.google.com/uc?export=download&id=0BxTexXJx0k4KcEwzeXpSQmxEOVU 

### How to use processComments.pl
The script itself is an example of how to use multiple workers to take advantage of multiple cores on 
modern CPUs to do a lot of work quickly.  This script reads data from STDIN and will process data from 
each Reddit comment and dump it in /tmp/output.txt

To run the script, use the following syntax:

processComment.pl 1 < data_file (Only use one worker -- slowest) 

processComments.pl 4 < data_file  (This would create four workers)

processComments.pl < data_file (This would create a worker for every available core.  This is the 
fastest method)

### How fast is it?

Using a modern i7-4770 CPU and reading from an SSD drive, it will process and decode 500,000 
JSON objects per second.  The script is generally I/O bound on most systems when invoked to use as 
many workers as there are cores.  

### Can I use it to process other things like Reddit posts?

Yes!  You will need to look at the section of code that is in the subroutine "process_json."  You can 
modify the JSON keys that you are interested in based on what data you are feeding the script.

### I'm getting errors when I run this.  What's going on?

If you get an error when trying to invoke this script, you are probably lacking some dependencies.  If 
you are using Ubuntu, make sure to install build-essential:
```
apt-get install build-essential
```
You can install all the Perl modules at once using:
```
cpan Cpanel::JSON::XS Fcntl Term::ANSIColor Time::HiRes Sys::Info
``` 
### What is the output of this script?

The output is a file with a bunch of lines that look like this:

26200367469,4606680,24933551,26200361113,1293855818,3,0
26200367476,4594350,24930501,26200340861,1293855825,1,0
26200367483,4594374,24914071,26200365693,1293855833,1,0
26200367490,4594350,24934275,26200367218,1293855836,2,0
26200367497,4602843,24933542,26200360315,1293855842,1,0

The first number is the reddit comment id in base 10 (Reddit uses base 36 ids for most things).  The second number is the subreddit id in which that 
particular comment was posted.  The third number is the link id (otherwise known as submission or post) for the comment.  The fourth number is the 
parent id of the comment.  This is either another comment id or a link id based on how large the number is.  The last two numbers are the score for 
the comment and the number of times the comment was gilded.
