package XYZ; 

use strict; 
use warnings; 

use Exporter; 
use IO::File; 

use Math::Linalg qw/sum product ascale mat_mul inverse print_array print_mat/;  
use Periodic qw/atomic_number/;  
use Util qw/read_file/; 

our @geometry  = qw/cart_to_direct direct_to_cart set_pbc atom_distance color_magmom/; 
our @xyz       = qw/info_xyz read_xyz print_xyz/; 
our @visualize = qw/xmakemol/; 

our @ISA         = qw/Exporter/; 
our @EXPORT      = ( );  
our @EXPORT_OK   = ( @geometry, @xyz, @visualize ); 
our %EXPORT_TAGS = (
    geometry  => \@geometry, 
    visualize => \@visualize, 
); 

#----------#
# GEOMETRY # 
#----------#

# convert cartesian to direct coordinate 
# args 
# -< ref to 2d array of lattice vectors 
# -< ref to 2d array of direct coordinates 
# return
# -> direct coordinates   
sub cart_to_direct { 
    my ( $lat, $cart ) = @_; 
    
    # remove selective dynamics tags and count
    map { splice @$_, 3, 4 } @$cart; 

    # direct = cart x lat-1
    my @inverse_lat = inverse(@$lat); 
    my @direct = mat_mul($cart, \@inverse_lat);  
    
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
sub direct_to_cart { 
    my ( $fh, $scaling, $lat, $label, $coor, $nx, $ny, $nz ) = @_; 
    my ( $x, $y, $z ); 

    # atom index 
    my $index = 0; 

    for my $atom ( @$coor ) { 
        # expand the supercell
        for my $iz (0..$nz-1) { 
            for my $iy (0..$ny-1) { 
                for my $ix (0..$nx-1) { 
                    # hard coded convert to cartesian
                    $x = $lat->[0][0]*($atom->[0]+$ix)+$lat->[1][0]*($atom->[1]+$iy)+$lat->[2][0]*($atom->[2]+$iz); 
                    $y = $lat->[0][1]*($atom->[0]+$ix)+$lat->[1][1]*($atom->[1]+$iy)+$lat->[2][1]*($atom->[2]+$iz); 
                    $z = $lat->[0][2]*($atom->[0]+$ix)+$lat->[1][2]*($atom->[1]+$iy)+$lat->[2][2]*($atom->[2]+$iz); 
                    #print_array($fh, '%-3s3%10.3f', $label->[$index++], $x, $y, $z); 
                    printf $fh "%-3s %10.3f %10.3f %10.3f\n", $label->[$index++], $x, $y, $z;  
                }
            }
        }
        
    }
    
    return; 
}

sub color_magmom { 
    my ( $label, $magmom ) = @_;   

    my %color = ( 
        'zero' => 'Bh', 
        'up'   => 'Hs', 
        'down' => 'Mt'
    ); 

    my $cutoff = 0.5;  

    for ( 0..$#$magmom ) { 
        # small magmom -> white 
        if ( abs($magmom->[$_] ) < $cutoff ) { 
            $label->[$_] = $color{zero}; 
        # spin-up
        } elsif ( $magmom->[$_] > 0 ) { 
            $label->[$_] = $color{up};  
        # spin-down 
        } else { 
            $label->[$_] = $color{down}; 
        }
    }

    return; 
}

# shift direct coordinate  
# args 
# -< ref to 2d array of coordinates 
# -< ref to 1d array of shifting 
# return 
# -> null
sub set_pbc { 
    my ($geometry, $dx, $dy, $dz) = @_; 

    for my $atom ( @$geometry ) { 
        if ( $atom->[0] > $dx ) { $atom->[0] -= 1.0 } 
        if ( $atom->[1] > $dy ) { $atom->[1] -= 1.0 } 
        if ( $atom->[2] > $dz ) { $atom->[2] -= 1.0 } 
    }

    return; 
}

# distance between two atom
# args 
# -< ref to two cartesian vectors 
# return
# -> distance 
sub atom_distance { 
    my ($atm1, $atm2) = @_; 

    my $d12 = sqrt(($atm1->[1]-$atm2->[1])**2 + ($atm1->[2]-$atm2->[2])**2 + ($atm1->[3]-$atm2->[3])**2); 

    return $d12; 
}

#-----#
# XYZ # 
#-----#
# xyz information 
# args 
# -< ref to array of atom 
# -< ref to array of natom 
# -< nx, ny, nz 
# return 
# -> total number of atom 
# -> xyz label
sub info_xyz { 
    my ( $atom, $natom, $nx, $ny, $nz ) = @_; 

    my @snatom = ascale(product($nx, $ny, $nz), @$natom); 
    my $ntotal = sum(@snatom); 
    my @label  = map { ( $atom->[$_] ) x $snatom[$_] } 0..$#$atom; 

    return ($ntotal, \@label) 
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

    my @lines = read_file($file); 

    my %struct; 
    my $ntotal  = shift @lines; 
    my $comment = shift @lines || ''; 

    for ( @lines ) { 
        my ( $element, $x, $y, $z ) = split; 
        push @{$struct{$element}}, [ $x, $y, $z ]; 
    }

    # sort element based on atomic number 
    my @atoms    = sort { atomic_number($a) <=> atomic_number($b) } keys %struct;  
    my @natoms   = map scalar(@{$struct{$_}}), @atoms;  
    my @geometry = map @{$struct{$_}}, @atoms; 
    
    return ( $comment, \@atoms, \@natoms, \@geometry ); 
}

# print xyz coordinates 
# args 
# -< output file
# -< total number of atom 
# -< xyz comment 
# -< ref of array of atom 
# -< ref of array of natom 
# -< ref of 2d array of coordinate 
# returns 
# -> null 
sub print_xyz { 
    my ( $file, $comment, $atom, $natom, $geometry ) = @_;  

    my $fh = IO::File->new($file, 'w') or die "Cannot write to $file\n"; 

    # xyz label 
    my @labels = map { ($atom->[$_]) x $natom->[$_] } 0..$#$atom;  
       
    # print header 
    printf $fh "%d\n", sum(@$natom); 
    printf $fh "%s\n", $comment; 

    # print coordinate 
    for  ( 0..$#labels ) { 
        print_array($fh, '%-3s3%10.3f', $labels[$_], @{$geometry->[$_]}); 
    }

    return; 
}

#-----------#
# VISUALIZE #
#-----------#

# visualize xyz file 
# args 
# -< xyz file 
# -< quiet mode (0|1)
# return : 
# -> null
sub xmakemol { 
    my ( $file, $quiet )  = @_; 

    $quiet = defined $quiet ? $quiet : 0; 

    unless ( $quiet ) { 
        print "=> xmakemol $file ...\n"; 
        my $bgcolor = $ENV{XMAKEMOL_BG} || '#D3D3D3'; 
        system "xmakemol -c '$bgcolor' -f $file >/dev/null 2>&1 &" 
    }    
    
    return; 
}

# last evaluated expression 
1; 
