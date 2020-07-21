#!/usr/bin/env perl
#


#open(OUTPUT, ">autoexec.rem");   # The > means open for write, 
                                 #  over original if existed.

#while (<INPUT>)
#  {
#  my($line) = $_;  #preserve $_, the line just read, nomatter what
#  chomp $line;     #blow off trailing newline

# unless($line =~ /^\s*rem/i)    #see regular expressions for explanation

#  if( m/^SUMM/)    #see regular expressions for explanation
#    {
#    print "$_";      #write the non-remmed autoexec command
#        if ($line =~m/^SUMMARY/){
#        print "$line\n";
#        }
#    }
#  }

open(INPUT,  "Home.ics");
while (<INPUT>) {  # read from standard input or files in @ARGV
 if (/^BEGIN:VEVENT/ .. /^END:VEVENT/){
    print if (/^SUMM|^DTSTART|^ORGAN/);
    print "\n" if (/^END:VEVENT/);
    
    }
 }
  print "\n" ;


close(INPUT);

#close(OUTPUT);