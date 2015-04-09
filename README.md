# reddit-tools
Collection of tools to process data from Reddit

## processComments.pl
This is a Perl script that enables processing comment JSON objects.  You can find sample data for this 
script at the following locations:

Small file:  https://drive.google.com/file/d/0BxTexXJx0k4KNGFBUGRUUnlOX0E/view?usp=sharing 
Larger file: https://drive.google.com/file/d/0BxTexXJx0k4KcEwzeXpSQmxEOVU/view?usp=sharing 

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

Using a modern i7-4770 CPU and reading from an SSD drive, it will process decode and process 500,000 
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
