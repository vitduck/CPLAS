package XYZ; 

use strict; 
use warnings; 

use Exporter   qw( import ); 
use List::Util qw( sum ); 
use constant ARRAY  => ref []; 

use Math       qw( dot_product mat_mul inverse ); 
use Periodic; 

# symbol 
our @geometry  = qw( cart_to_direct direct_to_cart set_pbc atom_distance ); 
our @xyz       = qw( read_xyz print_xyz ); 
our @visualize = qw( xmakemol ); 
our @print     = qw( print_comment print_coordinate ); 

# default import 
our @EXPORT = ( @geometry, @xyz, @print, @visualize ); 

# tag import 
our %EXPORT_TAGS = (
    geometry  => \@geometry, 
    print     => \@print, 
    visualize => \@visualize, 
); 

############
# GEOMETRY # 
############

# convert cartesian to direct coordinate 
# args 
# -< scaling constant 
# -< ref to 2d array of lattice vectors 
# -< ref to 2d array of direct coordinates 
# -< coordinate type; 
# return
# -> direct coordinates   
sub cart_to_direct { 
    my ($scaling, $lat, $geometry, $type) = @_; 
    
    if ( $type =~ /^\s*c/i ) {  
        # strip the selective dynamics tag 
        @$geometry = map [splice @$_, 0, 3], @$geometry;  
        # scale the coordinate 
        $geometry = mat_mul($scaling, $geometry); 
        # direct = cart x lat-1
        $geometry = mat_mul($geometry, inverse($lat)); 
        # undo any centering 
        #for my $atom (@$geometry) { 
            #map { $atom->[$_] += 1.0 if $atom->[$_] < 0 } 0..2; 
        #}
    }
    
    return $geometry;  
}

# convert POSCAR/CONTCAR/XDATCAR to xyz 
# args
# -< output file handler 
# -< scaling constant 
# -< ref to 2d array of lattive vectors 
# -< ref to 1d array of expanded atomic labels 
# -< ref to 2d array of atomic coordinates
# -< ref to coordinate shifting array
# -< ref to expansion array x,y,z
# return 
# -> null 
sub direct_to_cart { 
    my ($fh, $scaling, $lat, $label, $coor, $dxyz, $nx, $ny, $nz) = @_; 
    my ($x, $y, $z, @xyz);  

    # atom index 
    my $index = 0; 
    #set_pbc($coor, $dxyz); 

    for my $atom ( @$coor ) { 
        # coordinate shift, careful with reference
        my @atoms = @$atom; 
        map { $atoms[$_] -= 1.0 if $atoms[$_] > $dxyz->[$_] } 0..2; 
        # expand the supercell
        for my $iz (@$nz) { 
            for my $iy (@$ny) { 
                for my $ix (@$nx) { 
                    # convert to cartesian
                    $x = $lat->[0][0]*($atoms[0]+$ix)+$lat->[1][0]*($atoms[1]+$iy)+$lat->[2][0]*($atoms[2]+$iz); 
                    $y = $lat->[0][1]*($atoms[0]+$ix)+$lat->[1][1]*($atoms[1]+$iy)+$lat->[2][1]*($atoms[2]+$iz); 
                    $z = $lat->[0][2]*($atoms[0]+$ix)+$lat->[1][2]*($atoms[1]+$iy)+$lat->[2][2]*($atoms[2]+$iz); 
                    print_coordinate($fh, $label->[$index++], $x, $y, $z); 
                }
            }
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
    my ($geometry, $dxyz) = @_; 

    for my $atom ( @$geometry ) { 
        map { $atom->[$_] -= 1.0 if $atom->[$_] > $dxyz->[$_] } 0..2; 
    }

    return; 
}

# distance between two atom
# args 
# -< ref to two cartesian vectors 
# return
# -> distance 
sub atom_distance { 
    my ($xyz1, $xyz2) = @_; 
    my $d12 = sqrt(($xyz1->[1]-$xyz2->[1])**2 + ($xyz1->[2]-$xyz2->[2])**2 + ($xyz1->[3]-$xyz2->[3])**2); 

    return $d12; 
}

####### 
# XYZ # 
####### 

# read xyz coordinates 
# args 
# -< ref of xyz lines 
# return 
# -> total number of atom 
# -> xyz comment 
# -> ref of array of atom 
# -> ref of array of natom 
# -> ref of 2d array of coordinate 
sub read_xyz { 
    my ($line)  = @_; 

    my %struct; 
    my $ntotal  = shift @$line; 
    my $comment = shift @$line || ''; 

    for ( @$line ) { 
        my ($element, $x, $y, $z) = split; 
        # initialize coordinate array of element  
        unless ( exists $struct{$element} ) {   
            $struct{$element} = [] 
        }
        push @{$struct{$element}}, [ $x, $y, $z ]; 
    }

    my $atom     = [ sort { $Periodic::table{$a}[0] <=> $Periodic::table{$b}[0] } keys %struct ]; 
    my $natom    = [ map { scalar @{$struct{$_}} } @$atom ];  
    my $geometry = [ map { @{$struct{$_}} } @$atom ]; 
    
    return ($comment, $atom, $natom, $geometry); 
}

# print xyz coordinates 
# args 
# -< total number of atom 
# -< xyz comment 
# -< ref of array of atom 
# -< ref of array of natom 
# -< ref of 2d array of coordinate 
# returns 
# -> null 
sub print_xyz { 
    my ($fh, $comment, $atom, $natom, $geometry) = @_;  

    # xyz label 
    my @labels = map { ($atom->[$_]) x $natom->[$_] } 0..$#$atom;  
    
    # print header 
    printf $fh "%d\n", sum(@$natom); 
    printf $fh "%s\n", $comment; 
    # print coordinate 
    for  ( 0..$#labels ) { 
        print_coordinate($fh, $labels[$_], @{$geometry->[$_]}); 
    }

    return; 
}


#########
# PRINT #
#########

# print useful information into comment section of xyz file 
# args 
# -< file handler 
# -< comment format
# -< total number of atom 
# -< commnent 
# return 
# -> null
sub print_comment { 
    my ($fh, $format, $ntotal, @info) = @_; 
    printf $fh $format, $ntotal, @info;  

    return ; 
}

# print atomic coordinate block
# args 
# -< filehandler 
# -< atomic label 
# -< x, y, and z 
# return : 
# -> null
sub print_coordinate { 
    my ($fh, $label, $x, $y, $z) = @_; 
    printf $fh "%-2s  %7.3f  %7.3f  %7.3f\n", $label, $x, $y, $z; 

    return; 
}

#############
# VISUALIZE #
#############

# visualize xyz file 
# args 
# -< xyz file 
# -< quiet mode ? 
# return : 
# -> null
sub xmakemol { 
    my $file  = shift @_; 
    my $quiet = shift @_ || 0; 
    unless ( $quiet ) { 
        print "=> xmakemol $file ...\n"; 
        my $bgcolor = $ENV{XMAKEMOL_BG} || '#D3D3D3'; 
        system "xmakemol -c '$bgcolor' -f $file >/dev/null 2>&1 &" 
    }    
    
    return; 
}

# last evaluated expression 
1; 
