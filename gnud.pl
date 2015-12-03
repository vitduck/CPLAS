#!/usr/bin/env perl 

use strict; 
use warnings; 

use POSIX ":sys_wait_h";
use Time::HiRes qw(sleep);

die "Usage: gnud.pl [gnuplot script]\n" unless @ARGV; 

my $gnuplot = "gnuplot"; 
my $input = shift @ARGV; 
my $eps = parse_input($input); 

# fork the forking forker
my $pid = fork(); 
my $old = (stat($input))[9]; 

if ($pid) { 
    #I am your father
    while (1) { 
        my $new = (stat($input))[9]; 
        unless ( $new eq $old ) { 
            $old = $new; 
            # update the plot
            system $gnuplot, $input; 
            # send refresh signal
            kill SIGHUP => $pid;  
        }
        sleep 1; 
        # non-blocking call ?? 
        # not exactly, depends on mechanism of the shell 
        last if waitpid($pid, WNOHANG); 
    } 
} else { 
    # No... that's not true! That's impossible!
    exec 'gv', '-scale=2', $eps; 
}

# parse the gnuplot plot script 
sub parse_input { 
    my $input = shift; 
    my $eps; 
    
    open GNUPLOT, '<', $input or die "Cannot open $input\n"; 
    while (<GNUPLOT>) { 
        if (/(?<!#)set.+?(\w+\.eps)/) { 
            $eps =  $1;  
            last; 
        }
    }
    return $eps; 
}
