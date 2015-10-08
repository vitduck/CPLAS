package Math; 

use strict; 
use warnings; 

use Exporter   qw( import ); 
use List::Util qw( sum ); 

use constant ARRAY => ref []; 

# symbol 
our @vector = qw( max_length print_vec elem_product dot_product triple_product ); 
our @matrix = qw( print_mat mat_dim det mat_add mat_mul hstack vstack transpose inverse ); 
our @grid   = qw( mgrid ); 

# default import 
our @EXPORT = ( @vector, @matrix, @grid ); 

# tag import 
our %EXPORT_TAGS = ( 
    vector => \@vector, 
    matrix => \@matrix, 
    grid   => \@grid,
); 

#--------#
# VECTOR # 
#--------#

# largest character length of vector's elements 
# args
# -< $ref of vector 
# return: 
# -> digit/character length 
sub max_length { 
    my @lists = @_; 
    
    # max digit length 
    my $length = ( sort {$b <=> $a} map length($_), @lists )[0]; 
    
    return $length; 
}

# print vector 
# args 
# -< ref of vector 
# return: 
# -> null 
sub print_vec { 
    my ($vec)  = shift @_; 
    my $format = shift @_ || sprintf "%ds", max_length(@$vec);  
    my $fh     = shift @_ || *STDOUT; 
    # repeated format     
    $format = "%$format " x @$vec; 
    printf $fh "$format\n", @$vec; 

    return;  
}

# numerical product of all vector's elements 
# arg: 
# -< ref of vector 
# return 
# -> product 
sub elem_product { 
    my ($vec) = @_; 

    my $product = 1;  
    for my $element (@$vec) { 
        $product *= $element; 
    }

    return $product; 
}

# dot vector product
# args
# -< (scalar, ref of vector) pair or refs of two vectors 
# return
# -> ref of scaled vector or dot product 
sub dot_product { 
    my @vectors = grep { ref $_ eq ARRAY  } @_; 

    if ( @vectors == 1 ) { 
        # scale vector by a scalar 
        my ($scalar) = grep { ! ref $_ } @_; 
        my $vector  = shift @vectors;  

        return [ map $scalar*$_, @$vector ]; 
    } else {  
        # dot product of two vector 
        my ($vec1, $vec2) = @vectors; 

        # compatability check
        unless ( @$vec1 == @$vec2 ) { die "IndexError: incompatible dimension\n" }

        return sum(map { $vec1->[$_]*$vec2->[$_] } 0..$#$vec1); 
    } 
}

# triple vector product
# args 
# -< refs of three vectors 
# return
# -> volume of spanned by three vectors 
sub triple_product { 
    my ($vec1, $vec2, $vec3) = @_; 

    # vstack three vectors and 
    my $mat = vstack([$vec1], [$vec2], [$vec3]); 

    # calculate the determinant of resulting 3x3 matrix
    return det($mat); 
}

#--------#
# MATRIX #
#--------#

# print 2D matrix  
# args 
# -< ref of matrix
# return
# -> null 
sub print_mat { 
    my $mat    = shift @_; 
    my $format = shift @_ || '15.8f'; 
    my $fh     = shift @_ || *STDOUT; 
    
    for my $row (@$mat) { 
        print_vec($row, $format, $fh); 
    }

    return; 
}

# dimesnion of arbitrary matrix 
# args 
# -< ref of matrix
# return
# -> array contains dimension of matrix
sub mat_dim { 
    my ($mat) = @_;  
    
    if (ref($mat->[0]) eq ARRAY) {  
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
# -< ref of a 3x3 matrix
# return
# -> det of matrix 
sub det { 
    my ($mat) = @_ ; 
    
    my $det =  $mat->[0][0]*$mat->[1][1]*$mat->[2][2] + 
               $mat->[0][1]*$mat->[1][2]*$mat->[2][0] + 
               $mat->[2][0]*$mat->[1][0]*$mat->[2][1] -
               $mat->[0][2]*$mat->[1][1]*$mat->[2][0] - 
               $mat->[0][1]*$mat->[1][0]*$mat->[2][2] - 
               $mat->[0][0]*$mat->[1][2]*$mat->[2][1]; 

    return $det; 
}

# add two matrices 
# args
# -< refs of two 2d matrices 
# return
# -> ref of sum 2d matrix
sub mat_add { 
    my ($mat1, $mat2) = @_; 

    my $mat3;  
    my ($mat1_nrow, $mat1_ncol) = mat_dim($mat1);  
    my ($mat2_nrow, $mat2_ncol) = mat_dim($mat2);  

    # compatability check
    unless ( $mat1_nrow == $mat2_nrow ) { die "IndexError: incompatible dimension\n" }
    unless ( $mat1_ncol == $mat2_ncol ) { die "IndexError: incompatible dimension\n" }

    for my $i (0..$mat1_nrow-1) { 
        for my $j (0..$mat1_ncol-1) { 
            $mat3->[$i][$j] = $mat1->[$i][$j] + $mat2->[$i][$j]; 
        }
    }  

    return $mat3;  
}

# stack matrices vertically 
# args
# -< list of refs of 2d matrices 
# return: 
# -> ref of stacked 2d matrix 
sub vstack { 
    my @mats = @_; 
    
    my $stacked_mat; 
    for my $r2mat ( @mats ) { 
        push @$stacked_mat, @$r2mat; 
    }

    return $stacked_mat; 
}

# stacked matrices horizontally 
# args 
# -< list of refs to 2d matrices 
# return 
# -> ref of stacked 2d matrix 
sub hstack { 
    my @mats = @_; 

    # 1: transposition 
    my @trans_mats = map { transpose($_) } @mats; 

    # 2: vtacking  
    my $stacked_mat = vstack(@trans_mats); 

    # 3: undo transposition 
    return transpose($stacked_mat); 
}

# product of two 
# matrices
# args 
# -< refs of two 2d matrices
# return
# -> ref of product matrix
sub mat_mul { 
    my $product;  
    my @mats    = grep { ref $_ eq ARRAY  } @_; 

    if ( @mats == 1 ) { 
        # scale the 2D matrix by a scalar 
        my ($scalar) = grep { ! ref $_ } @_; 
        my $mat      = shift @mats; 

        my ($nrow, $ncol) = mat_dim($mat); 
        for my $i (0..$nrow-1) { 
            for my $j ( 0..$ncol-1) { 
                $product->[$i][$j] = $scalar*$mat->[$i][$j]; 
            }
        } 
    } else { 
        # 2D matrix multiplication 
        my ($mat1, $mat2) = @mats; 
        my ($mat1_nrow, $mat1_ncol) = mat_dim($mat1);  
        my ($mat2_nrow, $mat2_ncol) = mat_dim($mat2);  
       
        # compatability check
        unless ( $mat1_ncol == $mat2_nrow ) { die "IndexError: incompatible dimension\n" }

        for my $i (0..$mat1_nrow-1) { 
            for my $j (0..$mat2_ncol-1) { 
                for my $k (0..$mat1_ncol-1) { 
                    $product->[$i][$j] += $mat1->[$i][$k] * $mat2->[$k][$j]; 
                }
            }
        }
    }

	return $product; 
}

# transpose 2d matrix 
# args
# -< ref to a 2D matrix
# return
# -> transposed matrix 
sub transpose { 
    my ($mat) = @_; 

    my $transposed;       
    my ($nrow, $ncol) = mat_dim($mat); 
    for my $i (0..$ncol-1) { 
        for my $j (0..$nrow-1) { 
            $transposed->[$i][$j] = $mat->[$j][$i];  
        }
    }

    return $transposed; 
}

# hardcoded inversion of a 3x3 matrix
# args 
# -< ref to a 3x3 matrix
# return
# -> inverse matrix 
sub inverse { 
    my ($mat) = @_; 
    
    my $inverse; 
    my $det = det($mat); 
    $inverse->[0][0] =  ($mat->[1][1]*$mat->[2][2] - $mat->[1][2]*$mat->[2][1])/$det; 
    $inverse->[0][1] = -($mat->[0][1]*$mat->[2][2] - $mat->[0][2]*$mat->[2][1])/$det; 
    $inverse->[0][2] =  ($mat->[0][1]*$mat->[1][2] - $mat->[0][2]*$mat->[1][1])/$det; 

    $inverse->[1][0] = -($mat->[1][0]*$mat->[2][2] - $mat->[1][2]*$mat->[2][0])/$det; 
    $inverse->[1][1] =  ($mat->[0][0]*$mat->[2][2] - $mat->[0][2]*$mat->[2][0])/$det; 
    $inverse->[1][2] = -($mat->[0][0]*$mat->[1][2] - $mat->[0][2]*$mat->[1][0])/$det; 

    $inverse->[2][0] =  ($mat->[1][0]*$mat->[2][1] - $mat->[1][1]*$mat->[2][0])/$det; 
    $inverse->[2][1] = -($mat->[0][0]*$mat->[2][1] - $mat->[0][1]*$mat->[2][0])/$det; 
    $inverse->[2][2] =  ($mat->[0][0]*$mat->[1][1] - $mat->[0][1]*$mat->[1][0])/$det; 
    
    return $inverse; 
}

#------# 
# GRID # 
#------# 

# generate cartesian grid 
# similar to numpy mgrid 
# args: 
# -< xrange, i.e. 100:600:100 
# -< yrange
# return 
# -> ref to 2d xgrid, ygrid
sub mgrid { 
    my ($xrange, $yrange) = @_; 

    # left:right:step 
    my ( $xl, $xr, $xs ) = split /:/, $xrange; 
    my ( $yl, $yr, $ys ) = split /:/, $yrange; 

    # number of grid point 
    my $nx = int(($xr - $xl)/$xs); 
    my $ny = int(($yr - $yl)/$ys); 

    # pseudo '2d' form of clum and row vector 
    my @x = map $xl + $_ * $xs, 0..$nx-1;  
    my @y = map $yl + $_ * $ys, 0..$ny-1;  
    
    # xgrid 
    my $xgrid; 
    for my $i (0..$nx-1) { 
        for my $j (0..$ny-1) { 
           $xgrid->[$i][$j] = $x[$i];  
        }
    }

    # ygrid 
    my $ygrid; 
    for my $i (0..$nx-1) {  
        for my $j (0..$ny-1) { 
            $ygrid->[$i][$j] = $y[$j]; 
        }
    }

    return ($xgrid, $ygrid); 
}

# last evaluated expression 
1;
