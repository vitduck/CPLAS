package Util; 

use strict; 
use warnings; 

use Exporter; 
use File::Basename; 
use File::Spec::Functions; 
use Tie::File; 

our @file  = qw( read_file slurp_file extract_file paragraph_file file_format );  
our @image = qw( set_eps_boundary eps2png view_eps view_png );  
our @tree  = qw( read_dir_tree print_dir_tree );  

our @ISA         = qw( Exporter );
our @EXPORT      = (); 
our @EXPORT_OK   = ( @file, @image, @tree );  
our %EXPORT_TAGS = (
    file  => \@file, 
    image => \@image, 
    tree  => \@tree, 
); 

# VASP files 
our @VASP = qw( 
    CHG CHGCAR CONTCAR DOSCAR 
    EIGENVAL INCAR KPOINTS LOCPOT
    OSZICAR OUTCAR PCDAT POSCAR 
    POTCAR PROCAR WAVECAR XDATCAR 
);  

# with sufficient thrust, pigs fly just fine
our %zenburn = 
( 
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
); 

#------#
# FILE # 
#------# 

# read file (line by line)
# args
# -< file 
# return
# -> array of lines 
sub read_file { 
    my ( $file ) = @_; 
   
    my @lines = (); 

    open my $fh, '<', $file or die "Cannot open $file\n"; 
    chomp ( @lines = <$fh> ); 
    close $fh; 
    
    return @lines;  
}

# read file (slurp mode)
# args
# -< file 
# return
# -> slurped line 
sub slurp_file { 
    my ( $file ) = @_; 
    
    open my $fh, '<', $file or die "Cannot open $file\n"; 
    my $line = do { 
        local $/ = undef; 
        <$fh>;   
    };  
    close $fh; 

    return $line;  
}

# read file (paragraph mode) 
# -< file 
# return 
# -> array of paragraphs
sub paragraph_file { 
    my ( $file ) = @_; 

    open my $fh, '<', $file or die "Cannot open $file\n"; 
    my @paragraphs = do {           
        local $/ = ''; 
        <$fh>; 
    };  
    close $fh; 

    return chomp ( @paragraphs ); 
}
    
# extract (lines from file)
# -< file 
# return 
# -> array of lines 
sub extract_file { 
    my ( $file, @linenrs ) = @_; 

    my @extracts = (); 
  
    # treat file as perl array !  
    if ( ! -e $file ) { die "$file does not exist\n" }
    tie my @lines, 'Tie::File', $file or die "Cannot tie to $file\n"; 

    # shift the array index (0-based)
    for ( @linenrs ) { push @extracts, $lines[$_-1] } 

    untie @lines; 
    
    return ( @extracts == 1 ? $extracts[0] : @extracts ); 
} 

# get file format 
# args 
# -< input files 
# return 
# -> file format
sub file_format { 
    my ( $file ) = @_;

    if ( grep $file eq $_, @VASP ) { return $file }

    # other files (list context) 
    my ( $format ) = ( $file =~ /.*\.(.+?)$/ ); 

    return $format; 
}

#-------#
# IMAGE #
#-------#

# set the correct eps boundary 
# due to bug of gnuplot 5 ???
# args 
# -< eps file 
# return 
# -> null 
sub set_eps_boundary { 
    my ( $eps ) = @_; 
    
    # boundary from gs 
    my @boundaries = ( split ' ', ( `gs -dQUIET -dBATCH -dNOPAUSE -sDEVICE=bbox $eps 2>&1` )[0] )[1..4]; 

    print "=> Fixing $eps boundaries: @boundaries\n"; 

    { # local scope for inline editing 
        local ( $^I, @ARGV ) = ( '~', $eps ); 
        while ( <> ) { 
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
    my ( $eps, $png, $density ) = @_; 

    # default
    $density = defined $density ? $density : 150; 

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
    my ( $eps, $scale ) = @_; 
    
    # default 
    $scale = defined $scale ? $scale : 2;     
    
    # lauch ghostview (gv)  
    print "=> gv -scale=$scale $eps\n"; 
    system "gv -scale=$scale $eps &"; 

    return; 
}

# view png file 
# args 
# -< png file 
# return 
# -> null 
sub view_png { 
    my ( $png ) = @_; 

    # lauch feh
    print "=> feh $png\n"; 
    system "feh $png &"; 

    return; 
}

#------#
# TREE #
#------#

# construct directory tree 
# args 
# -< top/root directory 
# return 
# -> hash ref of directory tree
sub read_dir_tree { 
    my ( $root ) = @_; 

    my %tree = ();  

    my @queue = ( [$root, \%tree] );  
    while ( my $next = shift @queue ) { 
        my ( $path, $href ) = @$next; 
        
        # use only basename for hash keys 
        my $basename = basename($path); 

        $href->{$basename} = do { 
            # symbolic is not fullly resolved! 
            if ( -f $path or -l $path ) { undef } 
            else { 
                # hash ref for sub-directories 
                my $sub_ref = {}; 

                # read content of directory then construct a list of ABSOLUTE path 
                # skip unresolved symbolic link (need more testing)
                opendir my $dfh, $path or die "Cannot open directory handler to $path\n"; 
                my @sub_paths = map { catfile($path, $_) } grep { ! /^\.\.?$/ } readdir $dfh; 
                closedir $dfh; 

                # breadth first (stack)
                unshift @queue, map { [$_, $sub_ref] } @sub_paths; 

                $sub_ref;
            }
        }; 
    }

    return %tree;  
} 

# print directory tree
# args 
# -< root directory
# -< hash ref of tree 
# -< bookmark directory [*]
# return 
# -> null  
sub print_dir_tree { 
    my ( $root, $tree, $current ) = @_; 
    
    # default
    $current = defined $current ? $current : undef; 

    my $indent = '| '; 
    my $leaf   = '\_'; 

    # write to tree.dat
    open my $fh, '>', "$root/tree.dat" or die "Cannot write to $root/tree.dat\n"; 
    
    my @queue  = ( [$root, $tree->{basename($root)}, 0] );  
    while ( my $next = shift @queue ) { 
        my ( $path, $href, $level ) = @$next; 

        # add sub directories to queue (with full path) 
        unshift @queue, 
        map ["$path/$_", $href->{$_}, $level+1],
        grep ref( $href->{$_} ) eq 'HASH', 
        sort keys %$href; 

        # tree branching 
        my $branch = ( $level == 0 ? '+' : ( $indent )x( $level-1 ).$leaf );  

        # print tree 
        printf $fh ( $current eq $path ? "%s%s [*]\n" : "%s%s\n" ), $branch, basename($path);  
    }
    close $fh; 

    return; 
}

# last evaluated expression 
1; 
