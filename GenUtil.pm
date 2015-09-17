package GenUtil; 

use strict; 
use warnings; 

use IO::File; 
use Exporter  qw( import ); 

our @EXPORT = qw ( read_line print_table ); 

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
    my @list = @_; 
    
    my $ncol    = 5; 

    # max digit length 
    my $dlength = ( sort {$b <=> $a} map length($_), @list )[0]; 
    
    while ( my @sublist = splice @list, 0, $ncol ) { 
        map { printf "%${dlength}d ", $_ } @sublist; 
        print "\n"; 
    }

    return; 
}

# last evaluated expression 
1; 
