package GenUtil; 

use strict; 
use warnings; 

use IO::File; 
use IO::Dir; 
use File::Basename; 
use File::Spec::Functions; 
use Data::Dumper; 
use Exporter qw( import ); 

use constant ARRAY => ref []; 

use Math qw( max_length print_vec );  

# symbolic 
our @read  = qw( read_line ); 
our @print = qw( print_table ); 
our @dir   = qw( read_dir_tree );  

# default import 
our @EXPORT = ( @read, @print, @dir ); 

######## 
# READ # 
######## 

# read lines of file: line by line or slurp mode 
# args
#   -> file 
# return
#   ->  ref of array of lines 
sub read_line { 
    my $input = shift @_;  
    my $mode  = shift @_ || '';  
    
    my $fh = IO::File->new($input, 'r') or die "Cannot open $input\n"; 
    my $line = $mode eq 'slurp' ? do { local $/=undef; <$fh> } : [<$fh>];  
    $fh->close;  
    
    # remove trailing \n 
    if ( ref $line eq ARRAY ) { chomp @$line }; 
    
    return $line; 
}

#########
# PRINT # 
#########

# print list using table format 
# args 
#   -> array of value
# return 
#   -> null
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

#############
# DIRECTORY #
#############

# construct directory tree 
# args 
#   -> directory 
# return 
#   -> hash contains directory and sub directory 
sub read_dir_tree { 
    my $root   = shift; 
    my $tree   = {}; 
    my @queue  = ( [ $root, $tree ] ); 

    while ( my $next = shift @queue ) { 
        my ( $path, $ref ) = @$next; 
        my $basename = basename($path); 

        $ref->{$basename} = do { 
            if ( -f $path or -l $path ) { undef } 
            else { 
                my $sub_ref = {}; 
                my $dirfh = IO::Dir->new($path); 
                my @sub_paths = map { catfile($path, $_) } grep { ! /^\.\.?$/ } $dirfh->read; 
                $dirfh->close; 
                push @queue, map { [ $_, $sub_ref ] } @sub_paths; 
                $sub_ref;
            }
        }; 
    }
    return $tree; 
} 

# last evaluated expression 
1; 
