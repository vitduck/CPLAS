package Math::Linalg; 

use strict; 
use warnings; 

use Exporter; 

use Fortran qw( fortran2perl );  

our @array  = qw( ascale norm dot triple vstack hstack print_array ); 
our @list   = qw( length max min sum product ); 
our @grid   = qw( mgrid );  
our @matrix = qw( mat_dim det mat_add mscale mat_mul transpose inverse print_mat ); 

our @ISA         = qw/Exporter/; 
our @EXPORT      = (); 
our @EXPORT_OK   = ( @array, @list, @grid, @matrix ); 
our %EXPORT_TAGS = ( 
    array  => \@array, 
    list   => \@list, 
    grid   => \@grid,
    matrix => \@matrix, 
); 

#------# 
# LIST # 
#------# 
#
# longest character length among array's elements 
# override perl built-in length function 
# args
# -< list
# return 
# -> digit/character length 
sub length { 
    my @array = @_; 
    
    # max digit/character length 
    my $length = ( sort { $b <=> $a } map length($_), @array )[0]; 
    
    return $length; 
}

# min of list
# args 
# -< list
# return 
# -> min element
sub min { 
    my @array = @_; 

    my $min = ( sort { $a <=> $b } @array )[0]; 

    return $min; 
}

# max of list
# args 
# -< array 
# return 
# -> max element
sub max { 
    my @array = @_; 

    my $max = ( sort { $b <=> $a } @array )[0]; 

    return $max; 
}

# numerical sum of all memebers 
# arg: 
# -< list
# return 
# -> sum 
sub sum { 
    my @array = @_; 

    my $sum = 0; 
    for ( @array ) { $sum += $_ }

    return $sum; 
}

# numerical product of all memebers  
# arg: 
# -< list
# return 
# -> product 
sub product { 
    my @array = @_; 

    my $product = 1;  
    for ( @array ) { $product *= $_ }

    return $product; 
}

#-------#
# ARRAY # 
#-------#

# scale array 
# args 
# -< scaling factor 
# -< array 
# return 
# -< scaled array 
sub ascale { 
    my ( $scaling, $array ) = @_; 
    
    return map $scaling*$_, @$array; 
} 

# dot product
# args
# -< ref of two arrays
# return
# -> dot product 
sub dot { 
    my ( $array1, $array2 ) = @_; 

    # compatability check
    unless ( @$array1 == @$array2 ) { die "IndexError: incompatible dimension\n" }

    my $dot = 0;  
    for ( 0..$#$array1 ) { 
        $dot += $array1->[$_]*$array2->[$_]; 
    }

    return $dot; 
}

# vector norm 
# args 
# -< array 
# return 
# -> vector norm 
sub norm { 
    my ( $array ) = @_; 
    
    return sqrt(sum(map $_**2, @$array)); 
}

# triple product
# args 
# -< refs of three vectors 
# return
# -> triple product (volume)
sub triple { 
    # vstack three vectors and 
    my @mat = vstack(@_); 

    # calculate the determinant of resulting 3x3 matrix
    return det(\@mat); 
}

# stack arrays vertically 
# args
# -< refs of arrays
# return 
# -> stacked 2d matrix 
sub vstack { 
    my @vstack = ();  
    for (@_) { 
        push @vstack, $_; 
    }
    
    return @vstack; 
}

# stack arrays horizontally 
# args 
# -< refs of arrays
# return 
# -> stacked 2d matrix 
sub hstack { 
    #1: stack arrays vertically 
    my @vstack = vstack(@_); 

    #2: undo transposition 
    return transpose(@vstack); 
}

# print array 
# args 
# -< filehandler 
# -< ref of array 
# -< fortran equivalent format 
# return 
# -> null 
sub print_array { 
    my ( $fh, $format, $array ) = @_; 

    my $perl_format = fortran2perl($format); 
    printf $fh "$perl_format\n", @$array;  

    return;  
}

#------# 
# GRID # 
#------# 

# generate cartesian grid 
# crude imitation of numpy's mgrid()
# args: 
# -< xrange, i.e. 100:600:100 
# -< yrange
# return 
# -> ref to 2d xgrid, ygrid
sub mgrid { 
    my ( $xrange, $yrange ) = @_; 

    # left:right:step 
    my ( $xl, $xr, $xs ) = split /:/, $xrange; 
    my ( $yl, $yr, $ys ) = split /:/, $yrange; 

    # number of grid point 
    my $nx = int(($xr - $xl)/$xs); 
    my $ny = int(($yr - $yl)/$ys); 

    # pseudo '2d' form of column and row vectors 
    my @x = map $xl + $_ * $xs, 0..$nx-1;  
    my @y = map $yl + $_ * $ys, 0..$ny-1;  
    
    # xgrid 
    my $xgrid; 
    for my $i ( 0..$nx-1 ) { 
        for my $j ( 0..$ny-1 ) { 
           $xgrid->[$i][$j] = $x[$i];  
        }
    }

    # ygrid 
    my $ygrid; 
    for my $i ( 0..$nx-1 ) {  
        for my $j ( 0..$ny-1 ) { 
            $ygrid->[$i][$j] = $y[$j]; 
        }
    }

    return ( $xgrid, $ygrid ); 
}

#--------#
# MATRIX #
#--------#

# dimesnion of arbitrary matrix (recursive)
# args 
# -< matrix
# return
# -> array dimension of matrix
sub mat_dim { 
    my ( $mat ) = @_;  
    
    if ( ref($mat->[0]) eq 'ARRAY' ) {  
        my @shape; 
        # recursive call 
        push @shape, (scalar @$mat, mat_dim($mat->[0])); 
        return @shape; 
    } else { 
        # halting condition 
        # ref to 1d array is reached 
        return scalar(@$mat); 
    }
}

# hardcoded determinant of a 3x3 matrix 
# args 
# -< a 3x3 matrix
# return
# -> det of matrix 
sub det { 
    my ( $mat ) = @_ ; 
    
    my $det =  $mat->[0][0]*$mat->[1][1]*$mat->[2][2] + 
               $mat->[0][1]*$mat->[1][2]*$mat->[2][0] + 
               $mat->[0][2]*$mat->[1][0]*$mat->[2][1] -
               $mat->[0][2]*$mat->[1][1]*$mat->[2][0] - 
               $mat->[0][1]*$mat->[1][0]*$mat->[2][2] - 
               $mat->[0][0]*$mat->[1][2]*$mat->[2][1]; 

    return $det; 
}

# add two matrices 
# args
# -< refs of 2d matrices 
# return
# -> 2d matrix whose element is sum of input matrices
sub mat_add { 
    my ( $mat1, $mat2 ) = @_; 

    my @mat_sum;  
    my ( $mat1_nrow, $mat1_ncol ) = mat_dim($mat1);  
    my ( $mat2_nrow, $mat2_ncol ) = mat_dim($mat2);  

    # compatability check
    if ( $mat1_nrow != $mat2_nrow ) { die "IndexError: incompatible dimension\n" }
    if ( $mat1_ncol != $mat2_ncol ) { die "IndexError: incompatible dimension\n" }

    for my $i ( 0..$mat1_nrow-1 ) { 
        for my $j ( 0..$mat1_ncol-1 ) { 
            $mat_sum[$i][$j] = $mat1->[$i][$j] + $mat2->[$i][$j]; 
        }
    }  

    return @mat_sum;   
}

# scale matrix 
# args 
# -< scaling factor 
# -< 2d matrix 
# return  
# -> scaled 2d matrix 
sub mscale { 
    my ( $scaling, $mat ) = @_; 
    
    my @scaled_mat; 

    my ( $nrow, $ncol ) = mat_dim($mat); 
    for my $i ( 0..$nrow-1 ) { 
        for my $j ( 0..$ncol-1) { 
            $scaled_mat[$i][$j] = $scaling*$mat->[$i][$j]; 
        }
    } 

    return @scaled_mat; 
}

# product of two matrices
# args 
# -< refs of two 2d matrices
# return
# -> 2d product matrix
sub mat_mul { 
    my ( $mat1, $mat2 ) = @_; 

    my @product; 
    
    # compatability check
    my ( $mat1_nrow, $mat1_ncol ) = mat_dim($mat1);  
    my ( $mat2_nrow, $mat2_ncol ) = mat_dim($mat2);  
    if ( $mat1_ncol != $mat2_nrow ) { die "IndexError: incompatible dimension\n" }

    for my $i ( 0..$mat1_nrow-1 ) { 
        for my $j ( 0..$mat2_ncol-1 ) { 
            for my $k ( 0..$mat1_ncol-1 ) { 
                $product[$i][$j] += $mat1->[$i][$k] * $mat2->[$k][$j]; 
            }
        }
    }

    return @product; 
}

# transpose 2d matrix 
# args
# -< ref to a 2D matrix
# return
# -> transposed matrix 
sub transpose { 
    my ( $mat ) = @_; 

    my @transposed;       

    my ( $nrow, $ncol ) = mat_dim($mat); 
    for my $i ( 0..$ncol-1 ) { 
        for my $j ( 0..$nrow-1 ) { 
            $transposed[$i][$j] = $mat->[$j][$i];  
        }
    }

    return @transposed; 
}

# hardcoded inversion of a 3x3 matrix
# args 
# -< a 3x3 matrix
# return
# -> inverse 3x3 matrix 
sub inverse { 
    my ( $mat ) = @_; 
    
    my @inverse; 
    my $det = det($mat); 

    $inverse[0][0] =  ($mat->[1][1]*$mat->[2][2] - $mat->[1][2]*$mat->[2][1])/$det; 
    $inverse[0][1] = -($mat->[0][1]*$mat->[2][2] - $mat->[0][2]*$mat->[2][1])/$det; 
    $inverse[0][2] =  ($mat->[0][1]*$mat->[1][2] - $mat->[0][2]*$mat->[1][1])/$det; 

    $inverse[1][0] = -($mat->[1][0]*$mat->[2][2] - $mat->[1][2]*$mat->[2][0])/$det; 
    $inverse[1][1] =  ($mat->[0][0]*$mat->[2][2] - $mat->[0][2]*$mat->[2][0])/$det; 
    $inverse[1][2] = -($mat->[0][0]*$mat->[1][2] - $mat->[0][2]*$mat->[1][0])/$det; 

    $inverse[2][0] =  ($mat->[1][0]*$mat->[2][1] - $mat->[1][1]*$mat->[2][0])/$det; 
    $inverse[2][1] = -($mat->[0][0]*$mat->[2][1] - $mat->[0][1]*$mat->[2][0])/$det; 
    $inverse[2][2] =  ($mat->[0][0]*$mat->[1][1] - $mat->[0][1]*$mat->[1][0])/$det; 
    
    return @inverse; 
}

# print 2D matrix  
# args 
# -< filehandler 
# -< fortran format 
# -< 2d mat
# return
# -> null 
sub print_mat { 
    my ( $fh, $format, $mat ) = @_; 
    
    for my $array (@$mat) { 
        print_array($fh, $format, $array);  
    }

    return; 
}

# last evaluated expression 
1;
