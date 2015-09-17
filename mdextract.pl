#!/usr/bin/env perl 

use strict; 
use warnings; 

use Getopt::Long; 
use Pod::Usage; 
use IO::File; 

use VASP    qw( read_md ); 
use XYZ     qw( retrieve_xyz print_header print_coordinate ); 

my @usages = qw( NAME SYSNOPSIS OPTIONS ); 

# POD 
=head1 NAME 

mdextract.pl: extract specific geometries along MD trajectry 

=head1 SYNOPSIS

mdextract.pl [-h] [-p] <profile> [-t] <trajectory> [ionic steps] 

=head1 OPTIONS  

=over 8 

=item B<-h>

Print the help message and exit.

=item B<-p> 

Potential energy file  (default: profile.dat)

=item B<-t> 

Trajectory file (default: traj.dat)

=back

=cut

# default optional arguments 
my $help       = 0; 
my $profile    = 'profile.dat'; 
my $trajectory = 'traj.dat'; 

# parse optional arguments 
GetOptions( 
    'h'   => \$help, 
    'p=s' => \$profile, 
    't=s' => \$trajectory, 
) or pod2usage(-verbose => 1); 

# help message
if ( $help or @ARGV == 0 ) { pod2usage(-verbose => 99, -section => \@usages) }

# ISTEP, T, F from profile.dat 
my %md = read_md($profile); 

# geometry from trajectory
my %xyz = retrieve_xyz($trajectory); 

# extract geometry from @ARGV 
for my $istep (@ARGV) { 
    # fail-safe
    unless ( exists $md{$istep} )    { die "=> $istep.xyz does not exist in MD profile\n" } 
    unless ( exists $xyz{$istep} ) { die "=> $istep.xyz does not exist in MD trajectory\n" } 

    # write xyz file  
    print "=> Extracting $istep.xyz\n";  
    my $fh = IO::File->new("$istep.xyz", 'w') or die "Cannot write to $istep.xyz\n";  
    
    my $coordinate = $xyz{$istep}; 
    print_header($fh, $coordinate, $istep, \%md); 
    for my $atom ( @$coordinate ) { 
        print_coordinate($fh, @$atom); 
    }        

    $fh->close; 
}
