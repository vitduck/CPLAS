package GenUtil; 

use strict; 
use warnings; 

use Data::Dumper; 
use Exporter qw( import ); 
use File::Basename; 
use File::Spec::Functions; 
use IO::Dir; 
use IO::File; 

use Math qw( max_length print_vec );  

use constant ARRAY => ref []; 

# symbolic 
our @read  = qw( read_line ); 
our @print = qw( print_table dump_return ); 
our @dir   = qw( read_dir_tree );  
our @eps   = qw( view_eps eps2png zenburnize set_boundary ); 
our @png   = qw( view_png ); 

# default import 
our @EXPORT = ( @read, @print, @dir, @eps, @png ); 

######## 
# READ # 
######## 

# read lines of file: line by line or slurp mode 
# args
# -< file 
# return
# ->  ref of array of lines 
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
# -< array of value
# return 
# -> null
sub print_table { 
    my $list   = shift @_; 
    my $format = shift @_ || sprintf "%ds", max_length(@$list);  
    my $fh     = shift @_ || *STDOUT;

    my @lists = @$list; 

    my $ncol = 7; 
    while ( my @sublist = splice @lists, 0, $ncol ) { 
        print_vec(\@sublist, $format, $fh); 
    }

    return; 
}

# dump data returns from subroutines 
# args 
# -< array of 'var' 
# return 
# -> null 
sub dump_return { 
    print Dumper($_) for @_; 
}

#############
# DIRECTORY #
#############

# construct directory tree 
# args 
# -< directory 
# return 
# -> hash contains directory and sub directory 
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

#######
# EPS #
#######

# convert default color to zenburn 
# args 
# -< eps file 
# return 
# -> null
sub zenburnize { 
    my ($eps) = @_; 

    print "=> With sufficient thrust, pigs fly just fine\n"; 
    
    my %zenburn = ( 
        black   => '#212121', 
        gray    => '#3F3F3F', 
        white   => '#DCDCCC', 
        cyan    => '#8CD0D3', 
        blue    => '#94BFF3', 
        red     => '#CC9393', 
        green   => '#7F9F7F', 
        magenta => '#ED8BB7', 
        purple  => '#C0BED1',
        yellow  => '#F0DFAF', 
        brown   => '#FFCFAF',
        orange  => '#DFAF8F',
    ),  

    return; 
}

# set the correct eps boundary 
# due to bug of gnuplot 5 ???
# args 
# -< eps file 
# return 
# -> null 
sub set_boundary { 
    my ($eps) = @_; 
    
    # boundary from gs 
    my @boundaries = (split ' ', (`gs -dQUIET -dBATCH -dNOPAUSE -sDEVICE=bbox $eps 2>&1`)[0])[1..4]; 

    print "=> Fixing $eps boundaries: @boundaries\n"; 

    { # local scope for inline editing 
        local ($^I, @ARGV) = ('~', $eps); 
        while (<>) { 
            s/(%%BoundingBox:).*/$1 @boundaries/;
            print;   
        }
    }
    # remove back-up eps 
    unlink "$eps~";

    return; 
}

# convert eps to png 
# args 
# -< eps file 
# -< png file 
# -< pixel  
# return 
# -> null 
sub eps2png { 
    my ($eps, $png, $density) = @_; 

    # convert to png 
    print "=> $eps to $png\n"; 
    system 'convert', '-density', $density, $eps, $png; 
        
    return; 
}

# open eps using ghostview 
# args 
# -< eps file 
# return 
# -> null 
sub view_eps { 
    my $eps  = shift @_; 
    my $scale = shift @_ || 2; 
    print "=> $eps\n"; 
    system "gv -scale=$scale $eps"; 
}

#######
# PNG # 
#######

# view png file 
# args 
# -< png file 
# return 
# -> null 
sub view_png { 
    my ($png) = @_; 
    print "=> $png\n"; 
    system  "feh $png"; 

    return; 
}

# last evaluated expression 
1; 
