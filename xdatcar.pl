#!/usr/bin/env perl 

use strict; 
use warnings; 

use Getopt::Long; 
use IO::File; 
use Pod::Usage; 

use Util qw/extract_file/; 
use VASP qw/read_lattice read_traj4 read_traj5 save_traj/;  
use XYZ  qw/info_xyz direct_to_cart set_pbc xmakemol/; 

my @usages = qw/NAME SYSNOPSIS OPTIONS/;

# POD 
=head1 NAME 
 
xdatcar.pl: convert XDATCAR to ion.xyz

=head1 SYNOPSIS

xdatcar.pl [-h] [-i] <XDATCAR> [-c] [-d dx dy dz] [-x nx ny nz] [-s] [-q] 

=head1 OPTIONS

=over 8 

=item B<-h>

Print the help message and exits.

=item B<-i> 

Input file (default: XDATCAR)

=item B<-c> 

Centralize the coordinate (default: no) 

=item B<-d> 

PBC shifting 

=item B<-x> 

Generate nx x ny x nz supercell (default: 1 1 1)

=item B<-s> 

Save trajectory to disk in quiet mode (default: no) 

=item B<-q> 

Quiet mode, i.e. do not launch xmakemol (default: no) 

=back

=cut

# default optional arguments 
my $help   = 0; 
my $quiet  = 0; 
my $save   = 0; 
my @nxyz   = ( ); 
my @dxyz   = ( ); 

# input & output
my $input  = 'XDATCAR'; 
my $xyz    = 'ion.xyz'; 

# parse optional arguments 
GetOptions(
    'h'      => \$help, 
    'i=s'    => \$input,
    'c'      => sub { 
        @dxyz = (0.5,0.5,0.5) 
    }, 
    'd=f{3}' => sub { 
        my ($opt, $arg) = @_; 
        push @dxyz, $arg;  
    }, 
    'x=i{3}' => sub { 
        my ($opt, $arg) = @_; 
        push @nxyz, $arg; 
    }, 
    's'      => \$save, 
    'q'      => \$quiet
) or pod2usage(-verbose => 1); 

# help message
if ( $help ) { pod2usage(-verbose => 99, -section => \@usages) } 

# determine the version of VASP 
my ( $isif, $title, $scaling, $lat, $atom, $natom, $traj ) = 
extract_file('XDATCAR', 4) =~ /CAR/ ? 
read_traj4($input) :  
read_traj5($input) ;   

# supercell box
my ($nx, $ny, $nz) = @nxyz ? @nxyz : (1,1,1);  

# total number of atom in supercell 
my ( $ntotal, $label ) = info_xyz($atom, $natom, $nx, $ny, $nz);  

# save direct coordinate to hash for lookup
my $count = 0;  
my %traj  = (); 

# write to xdatcar.xyz
my $fh = IO::File->new($xyz, 'w') or die "Cannot write to $xyz\n"; 

for ( @$traj ) { 
    $count++; 
    # scalar -> 2d array 
    my $geometry = [ map [ split ], split /\n/, $_ ];  

    # hash of original geometry
    $traj{$count} = $geometry; 
    
    # PBC
    if ( @dxyz ) { set_pbc($geometry, @dxyz) } 

    # print coordinate to ion.xyz
    printf $fh "%d\n# Step: %d\n", $ntotal, $count;  
    
    # ISIF = 2|4
    if ( $isif == 2 ) {    
        direct_to_cart($fh, $scaling, $lat, $label, $geometry, $nx, $ny, $nz); 
    # ISIF = 3 ( and VASP 4 )
    } else { 
        my $ilat = shift @$lat; 
        direct_to_cart($fh, $scaling, $ilat, $label, $geometry, $nx, $ny, $nz); 
    }
}

$fh->close; 

# store trajectory
$save ? save_traj('traj.dat', \%traj, $save) : xmakemol($xyz, $quiet); 
