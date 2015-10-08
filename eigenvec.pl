#!/usr/bin/env perl 

use strict; 
use warnings; 

use Data::Dumper; 
use Getopt::Long; 
use IO::File; 
use List::Util qw( sum ); 
use Pod::Usage; 

use GenUtil qw( read_line ); 
use Math    qw( elem_product dot_product mat_mul );   
use VASP    qw( read_cell read_geometry read_phonon_eigen ); 
use XYZ     qw( set_pbc cart_to_direct direct_to_cart print_comment print_coordinate xmakemol );

my @usages = qw( NAME SYSNOPSIS OPTIONS ); 

# POD 
=head1 NAME 
eigenvec.pl: visualize atomic displacement 

=head1 SYNOPSIS

eigenvec.pl [-h] [-c] [-s 0.5] [-m 1] [-f 10] [-q] 

=head1 OPTIONS

=over 8

=item B<-h>

Print the help message and exit.

=item B<-s> 

Scaling of the displacement vector 

=item B<-m> 

Eigenmode 

=item B<-f> 

Number of animation steps 

=item B<-c> 

Centralize the coordinate (default: no) 

=item B<-d> 

PBC shifting (default [1.0, 1.0. 1.0])

=item B<-q> 

Quiet mode, i.e. do not launch xmakemol (default: no) 

=back

=cut

# default optional arguments 
my $help  = 0; 
my $scale = 0.25; 
my $mode  = 0; 
my $freq  = 10; 
my @nxyz  = (1,1,1); 
my @dxyz  = (1.0, 1.0, 1.0); 
my $quiet = 0;  

# parse optional arguments 
GetOptions(
    'h'      => \$help, 
    's=f'    => \$scale, 
    'm=i'    => \$mode, 
    'f=f'    => \$freq, 
    'c'      => sub { 
        @dxyz = (0.5,0.5,0.5) 
    },  
    'd=f{3}' => sub { 
        my ($opt, $arg) = @_; 
        shift @dxyz; 
        push @dxyz, $arg;  
    }, 
    'q'      => \$quiet, 
) or pod2usage(-verbose => 1); 

# help message 
if ( $help or $mode == 0 ) { pod2usage(-verbose => 99, -section => \@usages) }

# read poscar 
my $poscar = read_line('POSCAR'); 
my ($title, $scaling, $lat, $atom, $natom, $dynamics, $type) = read_cell($poscar); 
my $geometry = read_geometry($poscar); 

# read eigen{vector,value}
my $eigen = read_phonon_eigen(read_line('OUTCAR')); 

# supercell box
my ($nx, $ny, $nz) = map [0..$_-1], @nxyz; 

# total number of atom in supercell 
$natom = dot_product(elem_product(\@nxyz), $natom); 
my $ntotal = sum(@$natom);  
my $label  = [map { ($atom->[$_]) x $natom->[$_] } 0..$#$atom];

# strip the selective dynamic tag 
if ( $dynamics ) { @$geometry = map [splice @$_, 0, 3], @$geometry } 

# set the pbc 
set_pbc($geometry, \@dxyz); 

# convert cart to direct
my $cartesian = mat_mul($geometry, $lat); 

# output 
my $output = "$mode.xyz"; 
my $fh = IO::File->new($output, 'w') or die "Cannot write to $output\n";  

for my $nstep (0..$freq) { 
    print_comment($fh, "%d\nf=%f meV\n", $ntotal, $eigen->{$mode}{f}); 
    for my $natom (0..$#$cartesian) { 
        my ($x, $y, $z) = @{$cartesian->[$natom]}[0..2]; 
        $x += $nstep*$scale*$eigen->{$mode}{dxyz}[$natom][0]/$freq; 
        $y += $nstep*$scale*$eigen->{$mode}{dxyz}[$natom][1]/$freq; 
        $z += $nstep*$scale*$eigen->{$mode}{dxyz}[$natom][2]/$freq; 
        print_coordinate($fh, $label->[$natom], $x, $y, $z); 
    }
}

$fh->close; 

# visualize 
xmakemol($output, $quiet); 
