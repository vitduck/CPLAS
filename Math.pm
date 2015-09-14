package Math; 

use strict; 
use warnings; 

use Exporter   qw( import ); 
use List::Util qw( sum ); 

use constant ARRAY => ref []; 

# symbol 
our @math   = qw( scalar_product triple_product matmul matdim ); 

# default import 
our @EXPORT = ( @math ); 

# tag import 
our %EXPORT_TAGS = ( 
    math => \@math, 
); 

######## 
# MATH # 
######## 
# scalar vector product
sub scalar_product { 
    my ($vec1, $vec2) = @_; 
    my $scalar = 0; 
    # dimension check
    unless ( @$vec1 == @$vec2 ) { die "IndexError: vector dimensions are not compatible\n" }
    $scalar = sum(map { $vec1->[$_]*$vec2->[$_] } 0..$#$vec1); 
   
    return $scalar; 
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

# dimesnion of arbitrary matrix 
# arg : 
#   - ref to matrix
# return :
#   - dimension of matrix
sub matdim { 
    my ($mat) = @_;  
    if (ref($mat->[0]) eq ARRAY) {  
        my @shape; 
        # recursive call 
        push @shape, (scalar @$mat, matdim($mat->[0])); 
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
sub matmul { 
	my ($mat1, $mat2) = @_;
	my @product = (); 
	my ($mat1_rows, $mat1_cols) = matdim($mat1);  
	my ($mat2_rows, $mat2_cols) = matdim($mat2);  
    # dimension check
    unless ( $mat1_cols == $mat2_rows ) { die "IndexError: matrix dimensions are not compatible\n" }
	for my $i (0..$mat1_rows-1) { 
		for my $j (0..$mat2_cols-1) { 
			for my $k (0..$mat1_cols-1) { 
				$product[$i][$j] += $mat1->[$i][$k] * $mat2->[$k][$j]; 
			}
		}
	}
	return @product; 
}

# last evaluated expression 
1;
