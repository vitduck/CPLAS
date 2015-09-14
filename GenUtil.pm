package GenUtil; 

use strict; 
use warnings; 

use Exporter  qw( import ); 

our @EXPORT = qw ( get_line print_table ); 

# read lines of file to array 
# arg : 
#   - file 
# return : 
#   - array of lines 
sub get_line { 
    my ($input) = @_; 
    open INPUT, '<', $input or die "Cannot open $input\n"; 
    chomp ( my @lines = <INPUT> ); 
    close INPUT; 

    return @lines; 
}

sub print_table { 
    my @list = @_; 
    
    my $ncol    = 8; 
    my $dlength = ( sort {$b <=> $a} map length($_), @list )[0]; 
    
    while ( my @sublist = splice @list, 0, $ncol ) { 
        map { printf "%${dlength}d ", $_ } @sublist; 
        print "\n"; 
    }

    return; 
}

# last evaluated expression 
1; 
