package Util; 

use strict; 
use warnings; 

use Exporter; 
use File::Basename; 
use File::Spec::Functions; 
use IO::Dir; 
use IO::File; 
use Tie::File; 

our @file  = qw/read_file slurp_file extract_file paragraph_file file_format/;  
our @image = qw/set_eps_boundary eps2png view_eps view_png/; 
our @tree  = qw/read_dir_tree print_dir_tree/; 

our @ISA         = qw/Exporter/;
our @EXPORT      = ( ); 
our @EXPORT_OK   = ( @file, @image, @tree );  
our %EXPORT_TAGS = (
    file  => \@file, 
    image => \@image, 
    tree  => \@tree, 
); 

# VASP files 
our @VASP = qw/ CHG CHGCAR CONTCAR DOSCAR 
                EIGENVAL INCAR KPOINTS LOCPOT
                OSZICAR OUTCAR PCDAT POSCAR 
                POTCAR PROCAR WAVECAR XDATCAR /; 

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
    
    my $fh = IO::File->new($file => 'r') or die "Cannot open $file\n"; 
    chomp ( my @lines = <$fh> ); 
    $fh->close;  
    
    return @lines; 
}

# slurp file
# -< file 
# return
# -> single scalar string 
sub slurp_file { 
    my ( $file ) = @_; 
    
    my $fh = IO::File->new($file => 'r') or die "Cannot open $file\n"; 
    my $line = do { local $/ = undef; <$fh> } ;  
    $fh->close; 

    return $line; 
}

# read file (paragraph mode) 
# -< file 
# return 
# -> array of paragraphs 
sub paragraph_file { 
    my ( $file ) = @_; 

    my $fh = IO::File->new($file => 'r') or die "Cannot open $file\n"; 
    chomp ( my @paragraph = do { local $/ = ''; <$fh> } ) ;  
    $fh->close; 

    return @paragraph;  
}
    
# extract (lines from file)
# -< file 
# -< line number 
# return 
# -> extracted line
sub extract_file { 
    my ( $file, $nline ) = @_; 
  
    # treat file as perl array!  
    tie my @lines, 'Tie::File', $file or die "Cannot tie to $file\n"; 

    # array's index starts from 0
    my $extract = $lines[$nline-1]; 
    untie @lines; 
    
    return $extract; 
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
    print "=> $eps\n"; 
    system "gv -scale=$scale $eps"; 

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
    print "=> $png\n"; 
    system "feh $png"; 

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

    my $tree = {}; 

    my @queue = ( [$root, $tree] );  
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
                my $dirfh = IO::Dir->new($path) or die "Cannot open directory handler to $path\n"; 
                my @sub_paths = map { catfile($path, $_) } grep { ! /^\.\.?$/ } $dirfh->read; 
                $dirfh->close; 

                # breadth first (stack)
                unshift @queue, map { [$_, $sub_ref] } @sub_paths; 

                $sub_ref;
            }
        }; 
    }

    return $tree; 
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
    my $fh = IO::File->new("$root/tree.dat" => 'w'); 
    
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

    $fh->close; 

    return; 
}

# last evaluated expression 
1; 
