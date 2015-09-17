package GenUtil; 

use strict; 
use warnings; 

use IO::File; 
use Exporter qw( import ); 

use Math     qw( max_length print_vec );  

our @EXPORT = qw ( read_line print_table print_array ); 

# read lines of file to array 
# arg : 
#   - file 
# return : 
#   - ref of array of lines 
sub read_line { 
    my ($input) = @_; 
    my $fh = IO::File->new($input, 'r') or die "Cannot open $input\n"; 
    chomp ( my @lines = <$fh> ); 
    $fh->close;  

    return \@lines; 
}

# print list using table format 
# arg : 
#   - array of value
# return: 
#   - null
sub print_table { 
    my $list   = shift @_; 
    my $format = shift @_ || sprintf "%ds", max_length($list);  
    my $fh     = shift @_ || *STDOUT; 

    my $ncol = 5; 
    while ( my @sublist = splice @$list, 0, $ncol ) { 
        print_vec(\@sublist, $format, $fh); 
    }

    return; 
}

# last evaluated expression 
1; 
