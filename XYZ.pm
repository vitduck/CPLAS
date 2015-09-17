package XYZ; 

use strict; 
use warnings; 

use Exporter   qw( import ); 
use List::Util qw( sum ); 
use Storable   qw( store retrieve ); 

use Math       qw( dot_product ); 

# symbol 
our @geom  = qw ( make_box make_label make_xyz read_xyz save_xyz retrieve_xyz atom_distance ); 
our @view  = qw ( xmakemol ); 
our @print = qw ( print_header print_coordinate ); 

# default import 
our @EXPORT = ( @geom, @view, @print ); 

# tag import 
our %EXPORT_TAGS = (
    geom  => \@geom, 
    view  => \@view, 
    print => \@print, 
); 

# xyz box
# arg : 
#   - ref to array of numbers of atoms
#   - expansion array nxyz
# return: 
#   - ref to array of xbox, ybox, and zbox. 
#   - total number of atom in the box
sub make_box { 
    my ($natom, @nxyz) = @_; 

    # array ref 
    my ($nx, $ny, $nz) = map { [0..$_-1] } @nxyz; 
    # natom for super cell 
    $natom = dot_product(@$nx*@$ny*@$nz, $natom); 
    # total number of atom 
    my $ntotal = sum(@$natom); 

    return ($nx, $ny, $nz, $ntotal); 
}

# xyz atomic label  
# arg : 
#   - ref to array of elements 
#   - ref to array of numbers of atoms
#   - expansion array nxyz
sub make_label { 
    my ($atom, $natom, @nxyz) = @_; 
    
    $natom = dot_product($nxyz[0]*$nxyz[1]*$nxyz[2], $natom); 
    # atomic label for super cell 
    my @label  = map {($atom->[$_]) x $natom->[$_]} 0..$#$atom;  
    
    return \@label; 
}

# convert POSCAR/CONTCAR/XDATCAR to xyz 
# arg : 
#   - output file handler 
#   - scaling constant 
#   - ref to 2d array of lattive vectors 
#   - ref to 1d array of expanded atomic labels 
#   - coordinate type (direct of cartesian) 
#   - ref to 2d array of atomic coordinates
#   - shift coordinate to center of cell ? 
#   - ref to expansion array x,y,z
# return: 
#   - 2d array of cartesian coordinates
sub make_xyz { 
    my ($fh, $scaling, $r2lat, $r2label, $type, $r2coor, $centralized, $nx, $ny, $nz) = @_; 
    my ($x, $y, $z, @xyz);  

    # loop trough all ionic steps 
    my $index = 0; 
    for my $atom ( @$r2coor ) { 
        # centralize coordinate 
        if ( $centralized ) {  
            $atom->[0] -= 1.0 if $atom->[0] > 0.5; 
            $atom->[1] -= 1.0 if $atom->[1] > 0.5; 
            $atom->[2] -= 1.0 if $atom->[2] > 0.5; 
        }
        # expand the supercell
        for my $ix (@$nx) { 
            for my $iy (@$ny) { 
                for my $iz (@$nz) { 
                    # write xyz
                    if ( $type =~ /D/i ) { 
                        # convert to cartesian
                        $x = $r2lat->[0][0]*$atom->[0] + $r2lat->[1][0]*$atom->[1] + $r2lat->[2][0]*$atom->[2]; 
                        $y = $r2lat->[0][1]*$atom->[0] + $r2lat->[1][1]*$atom->[1] + $r2lat->[2][1]*$atom->[2]; 
                        $z = $r2lat->[0][2]*$atom->[0] + $r2lat->[1][2]*$atom->[1] + $r2lat->[2][2]*$atom->[2]; 
                        # super cell 
                        $x += $scaling*($ix*$r2lat->[0][0] + $iy*$r2lat->[1][0] + $iz*$r2lat->[2][0]); 
                        $y += $scaling*($ix*$r2lat->[0][1] + $iy*$r2lat->[1][1] + $iz*$r2lat->[2][1]); 
                        $z += $scaling*($ix*$r2lat->[0][2] + $iy*$r2lat->[1][2] + $iz*$r2lat->[2][2]); 
                    } else { 
                        # super cell 
                        $x = $scaling*$atom->[0] + $ix*$r2lat->[0][0] + $iy*$r2lat->[1][0] + $iz*$r2lat->[2][0]; 
                        $y = $scaling*$atom->[1] + $ix*$r2lat->[0][1] + $iy*$r2lat->[1][1] + $iz*$r2lat->[2][1]; 
                        $z = $scaling*$atom->[2] + $ix*$r2lat->[0][2] + $iy*$r2lat->[1][2] + $iz*$r2lat->[2][2]; 
                    }
                    # print to output file via $fh 
                    print_coordinate($fh, $r2label->[$index], $x, $y, $z); 
                    push @xyz, [ $r2label->[$index++], $x, $y, $z ]; 
                }
            }
        }
    }

    return @xyz; 
}

sub read_xyz { 
    my ($line) = @_; 
    my @coordinates; 
    while ( my $atom = shift @$line ) { 
        if ( $atom =~ /^\s+$/ ) { last } 
        push @coordinates, [ (split ' ', $atom)[1..3] ];  
    }

    return @coordinates; 
}

# print useful information into comment section of xyz file 
# arg: 
#   - file handler 
#   - ref to 2d array of coordinate 
#   - ionic step (istep) 
#   - ref to potential hash (istep => [T,F])
sub print_header { 
    my ($fh, $coor, $istep, $md) = @_; 
    printf $fh "%d\n#%d:  T= %.1f  F= %-10.5f\n", scalar(@$coor), $istep, @{$md->{$istep}}; 

    return ; 
}

# print atomic coordinate block
# arg: 
#   - filehandler 
#   - atomic label 
#   - x, y, and z 
# return : 
#   - null
sub print_coordinate { 
    my ($fh, $label, $x, $y, $z) = @_; 
    printf $fh "%-2s  %7.3f  %7.3f  %7.3f\n", $label, $x, $y, $z; 

    return; 
}

# save trajectory to disk
# arg : 
#   - ref to trajectory (array of ref to 2d coordinate) 
#   - stored output
# return: 
#   - null
sub save_xyz { 
    my ($xyz, $output, $save) = @_; 

    if ( $save ) { 
        print  "=> Save trajectory as '$output'\n"; 
        printf "=> Hash contains %d entries\n", scalar(keys %$xyz); 
        store $xyz => $output 
    }

    return; 
}

# retrieve trajectory to disk
# arg : 
#   - stored data 
# return: 
#   - traj hash 
sub retrieve_xyz { 
    my ($stored_xyz) = @_; 

    # trajectory is required 
    die "$stored_xyz does not exists\n" unless -e $stored_xyz; 
    # retored traj as hash reference 
    my $xyz = retrieve($stored_xyz); 
    print  "=> Retrieve trajectory from '$stored_xyz'\n"; 
    printf "=> Hash contains %d entries\n\n", scalar(keys %$xyz); 

    return %$xyz; 
}

# visualize xyz file 
# arg : 
#   - xyz file 
#   - quiet mode ? 
# return : 
#   - null
sub xmakemol { 
    my ($file, $quiet) = @_; 
    unless ( $quiet ) { 
        print "=> xmakemol $file ...\n"; 
        my $bgcolor = $ENV{XMBG} || '#D3D3D3'; 
        exec "xmakemol -c '$bgcolor' -f $file >/dev/null 2>&1 &" 
    }    
}

# distance between two atom
# arg : 
#   - ref to two cartesian vectors 
# return : 
#   - distance 
sub atom_distance { 
    my ($xyz1, $xyz2) = @_; 
    my $d12 = sqrt(($xyz1->[1]-$xyz2->[1])**2 + ($xyz1->[2]-$xyz2->[2])**2 + ($xyz1->[3]-$xyz2->[3])**2); 

    return $d12; 
}

# last evaluated expression 
1; 
