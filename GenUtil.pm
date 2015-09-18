package GenUtil; 

use strict; 
use warnings; 

use IO::File; 
use Exporter qw( import ); 

use Math qw( max_length print_vec );  

our @EXPORT = qw ( read_line print_table print_array ); 

# read lines of file: line by line or slurp mode 
# arg : 
#   - file 
# return : 
#   - ref of array of lines 
sub read_line { 
    my $input = shift @_;  
    my $mode  = shift @_ || '';  
    
    my $fh = IO::File->new($input, 'r') or die "Cannot open $input\n"; 
    my $line = $mode eq 'slurp' ? do { local $/=undef; <$fh> } : [<$fh>];  
    $fh->close;  
    
    return $line; 
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

    my @lists = @$list; 

    my $ncol = 7; 
    while ( my @sublist = splice @lists, 0, $ncol ) { 
        print_vec(\@sublist, $format, $fh); 
    }

    return; 
}

# last evaluated expression 
1; 
