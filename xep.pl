#!/usr/bin/env perl 

use strict; 
use warnings; 

use Getopt::Long; 
use Pod::Usage; 

use GenUtil qw( view_eps view_png ); 
use XYZ     qw( xmakemol ); 
use Math    qw( max_length ); 

my @usages = qw(NAME SYSNOPSIS OPTIONS); 

# POD 
=head1 NAME 
 
xep.pl: xyz/eps/png viewer

=head1 SYNOPSIS

xep.pl [-h] [-f format]

=head1 OPTIONS

=over 8

=item B<-h>

Print the help message and exit

=item B<-e>

Menu for eps selection

=item B<-p>

Menu for png selection

=item B<-x>

Menu for xyz selection

=back

=cut

# default optional arguments 
my $help = 0;
my $menu = 0; 

my %table = (); 

# sub_ref table
my %view = (
    eps => \&view_eps, 
    png => \&view_png, 
    xyz => \&xmakemol, 
); 

# default output 
if ( @ARGV == 0 ) { pod2usage(-verbose => 1) }; 

# parse optional arguments 
GetOptions(
    'h' => \$help, 
    'e' => sub { 
        my @eps     = <*.eps>; 
        my %eps     = map { $_, $eps[$_] } 0..$#eps; 
        $table{eps} = \%eps; 
    }, 
    'p' => sub { 
        my @png     = <*.png>; 
        my %png     = map { $_, $png[$_] } 0..$#png; 
        $table{png} = \%png; 
    }, 
    'x' => sub { 
        my @xyz     = <*.xyz>; 
        my %xyz     = map { $_, $xyz[$_] } 0..$#xyz; 
        $table{xyz} = \%xyz; 
    }, 
) or pod2usage(-verbose => 1); 

# help message 
if ( $help ) { pod2usage(-verbose => 99, -section => \@usages) }  

# live or die, make your choice  
for my $format ( sort keys %table ) {     
    my $file   = $table{$format}; 
    # next loop if hash is empty 
    if ( keys %$file == 0 ) { next } 
    # format [digit]
    my $length = max_length(keys %$file); 
    # print table
    print "\n"; 
    map { printf "[%${length}d]  %s\n", $_, $file->{$_++} } sort { $a <=> $b } keys %$file; 
    while (1) { 
        print "=> "; 
        # remove newline, spaces, etc
        chomp (my $choice = <STDIN>); 
        $choice =~ s/\s+//g; 
        # shift chioce by -1
        if ( exists $file->{--$choice} ) {  
            $view{$format}->($file->{$choice}); 
            last; 
        }
    }
}

# let's the game begin 
for my $file ( @ARGV ) { 
    if ( $file =~ /.*\.(eps|png|xyz)/ ) { 
        my $format = $1; 
        $view{$format}->($file); 
    } else { 
        print "$file is not supported!\n"; 
    }
}
