#!/local/unix/bin/perl

#
# Reads the output of iostat(1), with args -xnp, and plots the data for
# the UFS partitions on the local box.  The partitions are obtained w/ a
# simple df.  The swap partition is grok'd from /etc/vfstab or hardcoded
# as commented below.
#
# Usage: piostat <file>
#
#        where <file> is a text file containing the data collected from
#        "iostat -xnp" output.
#
#
# Output is written to the current working directory.  The output consists
# of a PNG file for each partition and data set, and an HTML file which
# can be used to view the charts.  The HTML file is named iostat.html
#
# Kirk Vogelsang - Interliant (aka Net Daemons Associtates)
# kirk@nda.com : Fri Sep 24 14:47:00 EDT 1999
#




# This require the GD module.  Info on GD can be found at:
# http://www.genome.wi.mit.edu/ftp/pub/software/WWW/GD.html
use Chart::Plot;
use strict;

# No buffering
$| = 1;

#
# Small usage doo-dad
#
sub help {
    print <<EOF
Usage: $0 <file>

Where <file> is a text file containing the output of "iostat -xnp"
EOF
    ;
    exit 0;
}

#
# Grok the iostat output file and store it in a hash of sorts
#
sub grok_file {
    my ($file, $check_partitions) = @_;
    my %slice;

    open(FILE, "<$file") or die "Couldn't find $file: $!\n";
    while(<FILE>) {
	next unless /$check_partitions/;
	my ($a, $b, $c, $d, $e, $f, $g, $h, $i, $j, $k) = split " ";
	$slice{$k}{rdr}[$#{$slice{$k}{rdr}}+1] = $a;
	$slice{$k}{wps}[$#{$slice{$k}{wps}}+1] = $b;
	$slice{$k}{kbps}[$#{$slice{$k}{kbps}}+1] = $c;
	$slice{$k}{kbws}[$#{$slice{$k}{kbws}}+1] = $d;
	$slice{$k}{wait}[$#{$slice{$k}{wait}}+1] = $e;
	$slice{$k}{actv}[$#{$slice{$k}{actv}}+1] = $f;
	$slice{$k}{wsvc_t}[$#{$slice{$k}{wsvc_t}}+1] = $g;
	$slice{$k}{asvc_t}[$#{$slice{$k}{asvc_t}}+1] = $h;
	$slice{$k}{ptws}[$#{$slice{$k}{ptws}}+1] = $i;
	$slice{$k}{ptdb}[$#{$slice{$k}{ptdb}}+1] = $j;
    }
    close(FILE);
    return %slice;
}

#
# Plot the data and print some HTML
#
sub plot_data {
    my (%slice) = @_;
    my ($key, $var);

    foreach $key (keys %slice) {
	for $var ("rdr", "wps", "kbps", "kbws", "wait", "actv", "wsvc_t", "asvc_t", "ptws", "ptdb") {
	    my @data = ();
	    my $i;
	    for($i=0;$i<=$#{$slice{$key}{$var}};$i++) {
		push @data, $i, $slice{$key}{$var}[$i] +0.001;
	    }
	    my $plot = Chart::Plot->new;
	    $plot->setData (\@data) or die ( $plot->error() );
	    $plot->setGraphOptions ('title' => "$key: $var",
				    'horAxisLabel' => 'cycle',
				    'vertAxisLabel' => 'Data');
	    open(PLOT, ">$key-$var.png");
	    print PLOT $plot->draw();
	    close PLOT;
	    print HTML "<IMG SRC=\"$key-$var.png\"><P>\n";
	    if ($var eq "rdr") {print HTML "reads per second<P>\n"}
	    elsif ($var eq "wps") {print HTML "writes per second<P>\n"}
	    elsif ($var eq "kbps") {print HTML "kilobytes read per second<P>\n"}
	    elsif ($var eq "kbws") {print HTML "kilobytes written per second<P>\n"}
	    elsif ($var eq "wait") {print HTML "average number of transactions waiting for service (queue length<P>\n"}
	    elsif ($var eq "actv") {print HTML "average number of transactions  actively  beingserviced  (removed  from  the queue but not yet completed)<P>\n"}
	    elsif ($var eq "wsvc_t") {print HTML "average service time in  wait  queue,  in  milliseconds<P>\n"}
	    elsif ($var eq "asvc_t") {print HTML "average service time  active  transactions, in milliseconds<P>\n"}
	    elsif ($var eq "ptws") {print HTML "percent of time there are transactions  waiting for service (queue non-empty)<P>\n"}
	    elsif ($var eq "ptdb") {print HTML "percent of time the disk is busy  (transactions in progress)<P>\n"}
	}
    }
}

#
# Print the head comments to the html file
#
sub open_html {
    my ($swap) = @_;
    my $host = `hostname`;
    chop $host;

    print HTML "<HTML>\n";
    print HTML "<HEAD><TITLE>iostat results for $host</TITLE></HEAD>\n";
    print HTML "<BODY>";
    print HTML "Graphs were generated on: ";
    print HTML scalar localtime, "<P>\n";
    print HTML "<B>Swap partition: $swap</B><P>\n";
}

#
# Close the html file
#
sub close_html {
    print HTML "</BODY></HTML>";
    close HTML;
}

#
# Do all the stuff above
#
sub main {
    my ($file, $check_partitions);
    my @partitions = `/bin/df -k -F ufs|grep -v Filesystem|awk '{print \$1}'|awk -F/ '{print \$4}'`;

    my $swap = `grep swap /etc/vfstab|grep '^/dev'|awk '{print \$1}'|awk -F/ '{print \$4}'`;

#
# If the above line doesn't do the right thing, just hardcode it here
#
#    my $swap = 'c0t0d0s1'; 

    push @partitions, $swap;
    
    $check_partitions = join('|', @partitions);
    $check_partitions =~ s@\n@@g;

    open(HTML, ">iostat.html") or die "Couldn't open iostat.html: $!\n";
    
    if (! $ARGV[0]) { &help } else { $file = $ARGV[0]; }

    &open_html($swap);
    &plot_data(&grok_file($file, $check_partitions))
    &close_html();
}

#
# Start the ball rollin...
#
&main
