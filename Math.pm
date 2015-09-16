package Math; 

use strict; 
use warnings; 

use Exporter   qw( import ); 
use List::Util qw( sum ); 

use constant ARRAY  => ref []; 
use constant SCALAR => ref \0; 

# symbol 
our @vector = qw( dot_product triple_product ); 
our @matrix = qw( mat_print mat_dim mat_mul det inverse ); 

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
#  dot vector product
#  arg: 
#    - ref to scalar, vectors 
#   return: 
#    - scaled vector (scalar) or scalar (vectors) 
sub dot_product { 
    my @scalars = grep { ref $_ eq SCALAR } @_; 
    my @vectors = grep { ref $_ eq ARRAY  } @_; 

    if ( @scalars == 1 ) { 
        # scale vector by a scalar 
        my $scalar  = shift @scalars; 
        my $vector  = shift @vectors;  
        return map $$scalar*$_, @$vector; 
    } else {  
        # dot product of two vector 
        my ($vec1, $vec2) = @vectors; 
        unless ( @$vec1 == @$vec2 ) { die "IndexError: incompatible dimension\n" }
        return sum(map { $vec1->[$_]*$vec2->[$_] } 0..$#$vec1); 
    } 
}

# triple vector product
# arg : 
#   - ref to three vectors 
# return : 
#   - volume of spanned by three vectors 
sub triple_product { 
    my ($a, $b, $c) = @_; 
    my $product = $a->[0]*$b->[1]*$c->[2] - $a->[0]*$b->[2]*$c->[1]
                - $a->[1]*$b->[0]*$c->[2] + $a->[1]*$c->[0]*$b->[2]
                + $a->[2]*$b->[0]*$b->[1] - $a->[2]*$a->[2]*$b->[0]; 
    
    return $product; 
}

##########
# MATRIX #
##########
# print 2D matrix  
# arg : 
#   - ref to matrix
# return: 
#   - null 
sub mat_print { 
    my ($matrix) = @_; 
    
    my ($nrow, $ncol) = mat_dim($matrix); 
    my $format = "%15.8f" x $ncol; 
    for my $i (0..$nrow-1) { 
        printf "$format\n", @{$matrix->[$i]}; 
    }

    return; 
}

# dimesnion of arbitrary matrix 
# arg : 
#   - ref to matrix
# return :
#   - dimension of matrix
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

# product of two matrices
# arg : 
#   - ref of two 2d matrices
# return : 
#   - product matrix
sub mat_mul { 
    my @product = (); 
    my @scalars  = grep { ref $_ eq SCALAR } @_; 
    my @matrices = grep { ref $_ eq ARRAY  } @_; 

    if ( @scalars == 1 ) { 
        # scale the 2D matrix by a scalar 
        my $scalar = shift @scalars; 
        my $matrix = shift @matrices; 
        my ($nrow, $ncol) = mat_dim($matrix); 
        for my $i (0..$nrow-1) { 
            for my $j ( 0..$ncol-1) { 
                $product[$i][$j] = $$scalar*$matrix->[$i][$j]; 
            }
        } 
    } else { 
        # 2D matrix multiplication 
        my ($mat1, $mat2) = @matrices; 
        my ($mat1_rows, $mat1_cols) = mat_dim($mat1);  
        my ($mat2_rows, $mat2_cols) = mat_dim($mat2);  
        # dimension check
        unless ( $mat1_cols == $mat2_rows ) { die "IndexError: incompatible dimension\n" }
        for my $i (0..$mat1_rows-1) { 
            for my $j (0..$mat2_cols-1) { 
                for my $k (0..$mat1_cols-1) { 
                    $product[$i][$j] += $mat1->[$i][$k] * $mat2->[$k][$j]; 
                }
            }
        }
    }

	return @product; 
}

# hardcoded determinant of a 3x3 matrix 
# args: 
#    - ref to a 3x3 matrix
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

# hardcoded inversion of a 3x3 matrix
# args: 
#    - ref to a 3x3 matrix
# return: 
#    - inverse matrix 
sub inverse { 
    my ($mat) = @_; 
    
    my $det = det($mat); 
    my @inverse; 
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

# last evaluated expression 
1;
