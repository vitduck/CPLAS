package Math; 

use strict; 
use warnings; 

use Exporter   qw( import ); 
use List::Util qw( sum ); 

use constant ARRAY  => ref []; 

# symbol 
our @vector = qw( dot_product triple_product vec_print ); 
our @matrix = qw( mat_print mat_dim det mat_add mat_mul hstack vstack transpose inverse ); 

# default import 
our @EXPORT = ( @vector, @matrix ); 

# tag import 
our %EXPORT_TAGS = ( 
    vector => \@vector, 
    matrix => \@matrix, 
); 

##########
# VECTOR # 
##########
# print vector 
# arg: 
#   - ref of vector 
# return: 
#   - null 
sub vec_print { 
    my ($vec) = @_; 
    
    # vector format
    my $format = "%15.8f" x @$vec; 
    printf "$format\n", @$vec; 

    return; 
}

#  dot vector product
#  arg: 
#    - (scalar, ref of vector) pair or refs of two vectors 
#   return: 
#    - ref of scaled vector or dot product 
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
# arg : 
#   - refs of three vectors 
# return : 
#   - volume of spanned by three vectors 
sub triple_product { 
    my ($vec1, $vec2, $vec3) = @_; 

    # vstack three vectors and 
    my $mat = vstack([$vec1], [$vec2], [$vec3]); 

    # calculate the determinant of resulting 3x3 matrix
    return det($mat); 
}

##########
# MATRIX #
##########
# print 2D matrix  
# arg : 
#   - ref of matrix
# return: 
#   - null 
sub mat_print { 
    my ($mat) = @_; 
    
    my ($nrow, $ncol) = mat_dim($mat); 
    
    # column format 
    my $format = "%15.8f" x $ncol; 

    for my $i (0..$nrow-1) { 
        printf "$format\n", @{$mat->[$i]}; 
    }

    return; 
}

# dimesnion of arbitrary matrix 
# arg : 
#   - ref of matrix
# return :
#   - array contains dimension of matrix
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
# args: 
#    - ref of a 3x3 matrix
# return: 
#    - det of matrix 
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
# arg:
#   - refs of two 2d matrices 
# return: 
#   - ref of sum 2d matrix
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
# args: 
#    - list of refs of 2d matrices 
# return: 
#    - ref of stacked 2d matrix 
sub vstack { 
    my @mats = @_; 
    
    my $stacked_mat; 
    for my $r2mat ( @mats ) { 
        push @$stacked_mat, @$r2mat; 
    }

    return $stacked_mat; 
}

# stacked matrices horizontally 
# args: 
#    - list of refs to 2d matrices 
# return: 
#    - ref of stacked 2d matrix 
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
# arg : 
#   - refs of two 2d matrices
# return : 
#   - ref of product matrix
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
# args: 
#    - ref to a 2D matrix
# return: 
#    - transposed matrix 
sub transpose { 
    my ($mat) = @_; 

    my $transposed;       
    my ($nrow, $ncol) = mat_dim($mat); 
    for my $i (0..$nrow-1) { 
        for my $j (0..$ncol-1) { 
            $transposed->[$j][$i] = $mat->[$i][$j];  
        }
    }

    return $transposed; 
}

# hardcoded inversion of a 3x3 matrix
# args: 
#    - ref to a 3x3 matrix
# return: 
#    - inverse matrix 
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

# last evaluated expression 
1;
