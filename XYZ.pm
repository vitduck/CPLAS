package XYZ; 

use strict; 
use warnings; 

use Exporter; 

use Fortran qw( fortran2perl );  
use Math::Linalg qw( sum product ascale mat_mul inverse);  
use Periodic qw( atomic_number );  
use Util qw( read_file );  

our @geometry  = qw( cartesian_to_direct direct_to_cartesian print_cartesian set_pbc distance color_magmom );  
our @xyz       = qw( read_xyz print_xyz tag_xyz ); 
our @visualize = qw( xmakemol ); 

our @ISA         = qw( Exporter );  
our @EXPORT      = ();  
our @EXPORT_OK   = ( @geometry, @xyz, @visualize ); 
our %EXPORT_TAGS = (
    geometry  => \@geometry, 
    xyz       => \@xyz, 
    visualize => \@visualize, 
); 

#----------#
# GEOMETRY # 
#----------#

# shift direct coordinate  
# args 
# -< ref to 2d array of coordinates 
# -< ref to 1d array of shifting 
# return 
# -> null
sub set_pbc { 
    my ($geometry, $dxyz) = @_; 

    if ( @$dxyz == 0 ) { return }

    for my $atom ( @$geometry ) { 
        if ( $atom->[0] > $dxyz->[0] ) { $atom->[0] -= 1.0 } 
        if ( $atom->[1] > $dxyz->[1] ) { $atom->[1] -= 1.0 } 
        if ( $atom->[2] > $dxyz->[2] ) { $atom->[2] -= 1.0 } 
    }

    return; 
}

# convert cartesian to direct coordinate 
# args 
# -< poscar mode (cartesian||direct)
# -< ref to 2d array of lattice vectors 
# return
# -< 2d array of direct coordinates 
sub cartesian_to_direct { 
    my ( $lat, $cart ) = @_; 

    my @direct; 

    # remove selective dynamics tags and count
    map { splice @$_, 3, 4 } @$cart; 

    # direct = cart x lat-1
    @direct = mat_mul($cart, [inverse($lat)]);  

    return @direct;  
}

# convert POSCAR/CONTCAR/XDATCAR to xyz 
# args
# -< output file handler 
# -< scaling constant 
# -< ref to 2d array of lattive vectors 
# -< ref to 1d array of expanded atomic labels 
# -< ref to 2d array of atomic coordinates
# -< nx, ny, nz expansion
# return 
# -> null 
sub direct_to_cartesian { 
    my ( $cell, $geometry, $dxyz, $nxyz ) = @_; 

    # PBC shift 
    set_pbc($geometry, $dxyz); 
    
    # straight forward implementation to reduce subroutine calls
    # to be replaced with Incline::C ?
    my @xyz = (); 
    my ( $index, $x, $y, $z); 
    for my $atom ( @$geometry ) { 
        # expand the supercell
        for my $iz ( @{$nxyz->[2]} ) { 
            for my $iy ( @{$nxyz->[1]} ) { 
                for my $ix ( @{$nxyz->[0]} ) { 
                    # hard coded convert to cartesian
                    $x = $cell->[0][0]*($atom->[0]+$ix)+$cell->[1][0]*($atom->[1]+$iy)+$cell->[2][0]*($atom->[2]+$iz); 
                    $y = $cell->[0][1]*($atom->[0]+$ix)+$cell->[1][1]*($atom->[1]+$iy)+$cell->[2][1]*($atom->[2]+$iz); 
                    $z = $cell->[0][2]*($atom->[0]+$ix)+$cell->[1][2]*($atom->[1]+$iy)+$cell->[2][2]*($atom->[2]+$iz); 
                    push @xyz, [ $x, $y, $z ]; 
                }
            }
        }
    }

    return @xyz;  
}

sub print_cartesian { 
    my ( $comment, $tag, $xyz => $fh ) = @_; 

    # header 
    printf $fh "%d\n", scalar(@$tag); 
    printf $fh "%s\n", $comment;  

    # geometry block 
    for ( 0..$#$tag ) { 
        printf $fh "%-3s %10.3f %10.3f %10.3f\n", $tag->[$_], @{$xyz->[$_]}; 
    }
    
    return ; 
}

# color xyz according to value of magmom 
# args 
# -< color mode (0|1) 
# -< array ref of xyz tag 
# -< array ref of magmom 
# return 
# -> null
sub color_magmom { 
    my ( $tag, $magmom ) = @_;   

    my $cutoff = 0.5;  
    
    my %color = ( 
        'zero' => 'Bh', 
        'up'   => 'Hs', 
        'down' => 'Mt'
    ); 

    for ( 0..$#$magmom ) { 
        # small magmom -> white 
        if ( abs($magmom->[$_] ) < $cutoff ) { 
            $tag->[$_] = $color{zero}; 
        # spin-up
        } elsif ( $magmom->[$_] > 0 ) { 
            $tag->[$_] = $color{up};  
        # spin-down 
        } else { 
            $tag->[$_] = $color{down}; 
        }
    }

    return; 
}


# distance between two atom
# args 
# -< ref to two cartesian vectors 
# return
# -> distance 
sub distance { 
    my ($atm1, $atm2) = @_; 

    return sqrt(sum( map { ($atm1->[$_]-$atm2->[$_])**2 } 0..2));  
}

#-----#
# XYZ # 
#-----#

# atomic tag 
# args 
# -< array ref to array of atom 
# -< array ref to array of natom 
# -< array ref of expansion array 
# return 
# -> array of atomic tag 
sub tag_xyz { 
    my ( $atom, $natom, $nxyz, $mode ) = @_;  

    # tag of unitcell 
    my @unitcell = map { ( $atom->[$_] ) x $natom->[$_] } 0..$#$atom;  

    # apply supplementary data
    if ( exists $mode->{magmom} ) { color_magmom(\@unitcell, $mode->{magmom} ) }

    # expansion 
    my @ncell = map { scalar(@$_) } @$nxyz; 
    my @tags  = map { ( $_ ) x product(@ncell) } @unitcell; 

    return @tags;  
} 

# read xyz coordinates 
# args 
# -< file
# return 
# -> xyz comment 
# -> ref of array of atom 
# -> ref of array of natom 
# -> ref of 2d array of coordinate 
sub read_xyz { 
    my ( $file )  = @_; 

    my ( %xyz, %geometry, @lines ) = (); 

    ( $xyz{ntot}, $xyz{name}, @lines ) = read_file($file);  

    # loop through geometry block
    for my $index ( 0..$xyz{ntot}-1 ) { 
        my ( $element, $x, $y, $z ) = split ' ', $lines[$index];  
        # hash: element => coordinate 
        push @{$geometry{$element}}, [ $x, $y, $z ]; 
    }

    # array of elements  
    my @atoms = sort { atomic_number($a) <=> atomic_number($b) } keys %geometry; 

    # array of number of atom per element 
    my @natoms = map scalar(@{$geometry{$_}}), @atoms;  

    # array of geometry 
    my @geometry = map @{$geometry{$_}}, @atoms; 

    # complete xyz hash 
    @xyz{qw( atom natom geometry )} = ( \@atoms, \@natoms, \@geometry ); 
    
    return %xyz; 
}

# print xyz coordinates 
# args 
# -< hash ref of xyz
# -< output file
# returns 
# -> null 
sub print_xyz { 
    my ( $xyz => $file ) = @_;  

    # xyz label 
    my @nxyz = ( [0],[0],[0] ); 
    my @tags = tag_xyz($xyz->{atom}, $xyz->{natom}, \@nxyz );  

    open my $fh, '>', $file or die "Cannot write to $file\n"; 

    # print header 
    printf $fh "%d\n", sum(@{$xyz->{ntot}});  
    printf $fh "%s\n", $xyz->{name}; 

    # print coordinate 
    for  ( 0..$#tags ) { 
        print_array($fh,'%-3s3%10.3f', $tags[$_], $xyz->{geometry}[$_]);  
    }

    close $fh; 

    return; 
}

#-----------#
# VISUALIZE #
#-----------#

# visualize xyz file 
# args 
# -< quiet mode (0|1)
# -< xyz file 
# return : 
# -> null
sub xmakemol { 
    my ( $quiet, $file )  = @_; 

    # quiet mode 
    if ( $quiet ) { return }

    print "=> xmakemol $file ...\n"; 
    my $bgcolor = $ENV{XMAKEMOL_BG} || '#D3D3D3'; 
    system "xmakemol -c '$bgcolor' -f $file >/dev/null 2>&1 &"; 
    
    return; 
}

# last evaluated expression 
1; 
