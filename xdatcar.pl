#!/usr/bin/env perl 

use strict; 
use warnings; 

use Data::Dumper; 
use Getopt::Long; 
use IO::File; 
use Pod::Usage; 

use Util qw( extract_file );  
use MD   qw( save_traj ); 
use VASP qw( read_poscar read_xdatcar );  
use XYZ  qw( tag_xyz direct_to_cartesian print_cartesian set_pbc xmakemol ); 

my @usages = qw( NAME SYSNOPSIS OPTIONS );

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

Save trajectory to disk (default: no) 

=item B<-f> 

Show frozen atoms

=item B<-q> 

Quiet mode, i.e. do not launch xmakemol (default: no) 

=back

=cut

# default optional arguments 
my $help   = 0; 
my $input  = 'XDATCAR'; 
my @dxyz   = (); 
my @nxyz   = (); 
my $mode   = ''; 
my $quiet  = 0; 
my $save   = 0; 

my $xyz    = 'ion.xyz'; 
my $store  = 'traj.dat'; 
my %ref    = (); 

# parse optional arguments 
GetOptions(
    'h'      => \$help, 
    'i=s'    => \$input,
    's'      => \$save, 
    'q'      => \$quiet, 
    'd=f{3}' => \@dxyz, 
    'f'      => sub { $mode = 'frozen'; %ref = read_poscar('POSCAR') }, 
    'c'      => sub { @dxyz = (0.5,0.5,0.5) }, 
    'x=i{3}' => sub { push @nxyz, [0..$_[1]-1] }, 
) or pod2usage(-verbose => 1); 

# help message
if ( $help ) { pod2usage(-verbose => 99, -section => \@usages) } 

# read XDATCAR 
my %xdatcar = read_xdatcar($input); 

if ( $save ) { 
    # save trajectory to disk  
    my %trajectory = map { $_+1, $xdatcar{geometry}[$_] } 0..$#{$xdatcar{geometry}}; 
    save_traj(\%trajectory => $store);   
} else { 
    # pbc box 
    @nxyz = ( @nxyz == 0 ? ([0], [0], [0]) : @nxyz );  

    # make ion.xyz 
    my @tags = tag_xyz($xdatcar{atom}, $xdatcar{natom}, \@nxyz, $mode, $ref{frozen});  
    
    # write to xdatcar.xyz
    my $fh = IO::File->new($xyz, 'w') or die "Cannot write to $xyz\n"; 
    for ( 0.. $#{$xdatcar{geometry}} ) { 
        my @xyz = ();  
        my $comment = sprintf("Step: %d", $_+1); 

        if ( @{$xdatcar{cell}} == 1 ) {  
            # ISIF = 2|4 
            @xyz = direct_to_cartesian($xdatcar{cell}[0], $xdatcar{geometry}[$_], \@dxyz, \@nxyz); 
        } else { 
            # ISIF = 3 
            @xyz = direct_to_cartesian($xdatcar{cell}[$_], $xdatcar{geometry}[$_], \@dxyz, \@nxyz); 
        }
        # print ot file 
        print_cartesian($comment, \@tags, \@xyz => $fh);  
    }
    $fh->close; 

    if ( $quiet == 0 ) { xmakemol($xyz) } 
}
