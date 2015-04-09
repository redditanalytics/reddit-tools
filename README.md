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


