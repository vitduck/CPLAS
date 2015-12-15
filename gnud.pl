#!/usr/bin/env perl 

use strict; 
use warnings; 

use Getopt::Long; 
use Pod::Usage; 
use POSIX ":sys_wait_h";
use Time::HiRes qw(sleep);

use Gnuplot qw( read_output_eps ); 

my @usages = qw( NAME SYSNOPSIS OPTIONS );  

# POD 
=head1 NAME 

gnud.pl: gnuplot script watcher

=head1 SYNOPSIS

gnud.pl [-h] <gnuplot script>

=head1 OPTIONS

=over 8

=item B<-h>

Print the help message and exit.

=back

=cut

# default optional arguments
my $help   = 0; 

# parse optional arguments 
GetOptions(
    'h'      => \$help, 
) or pod2usage(-verbose => 1); 

# help message 
if ( $help or @ARGV == 0 ) { pod2usage(-verbose => 99, -section => \@usages) }

my $input = shift @ARGV; 
my $eps = read_output_eps($input);  

# fork the forking forker
my $pid = fork(); 
my $old = (stat($input))[9]; 

if ($pid) { 
    # I am your father
    while (1) { 
        # avoid the undef complain
        my $new = (stat($input))[9]; 
        
        unless ( $new eq $old ) { 
            $old = $new; 
            # update the plot
            system 'gnuplot', $input; 
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
