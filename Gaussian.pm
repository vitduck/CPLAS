package Gaussian; 

use Exporter;  
use IO::File; 

use Util qw/paragraph_file/;
use Periodic qw/atomic_number/; 
use Math::Linalg qw/print_array/; 

our @gaussian = qw/read_gaussian print_gaussian/;  

our @ISA         = qw/Exporter/;
our @EXPORT      = ( ); 
our @EXPORT_OK   = ( @gaussian ); 
our %EXPORT_TAGS = ( ); 

# parse gaussian input
# args 
# -< file
# -< ref of array of options 
# -< level of theory 
# -< title 
# -< charge 
# -< spin 
# -< ref of array of atom
# -< ref of array of natom 
# -< ref of 2d array of geometry
# return 
# -> null

sub read_gaussian { 
    my ( $file ) = @_;  
    
    # paragraph mode
    chomp ( my ( $header, $title, $structure ) = paragraph_file($file) );  
    
    # option 
    my @options = ( $header =~ /(\%.+?)\n/ );  

    # theory (no more trailing)
    my ( $theory ) = ( $header =~ /(#.+?)$/ );  

    # charge, spin and structure 
    my @lines = split /\n/, $structure; 
    ( $charge, $spin ) = split ' ', shift @lines; 

    # read the xyz block
    my %struct; 
    for ( @lines ) { 
        my ( $element, $x, $y, $z ) = split; 
        push @{$struct{$element}}, [ $x, $y, $z ]; 
    }

    # sort element based on atomic number 
    my @atoms    = sort { atomic_number($a) <=> atomic_number($b) } keys %struct;  
    my @natoms   = map scalar @{$struct{$_}}, @atoms;  
    my @geometry = map @{$struct{$_}}, @atoms;  

    return ( \@options, $theory, $title, $charge, $spin, \@atoms, \@natoms, \@geometry );  
}

# print gaussian input 
# args
# -< output file
# -< option 
# -< level of theory 
# -< title 
# -< charge 
# -< spin 
# -< array of atom
# -< array of natom 
# -< 2d array of geometry
# return 
# -> null 
sub print_gaussian { 
    my ( $file, $option, $theory, $title, $charge, $spin, $atom, $natom, $geometry ) = @_;  

    my $fh = IO::File->new($file, 'w') or die "Cannot write to $file\n"; 

    # xyz label 
    my @labels = map { ($atom->[$_]) x $natom->[$_] } 0..$#$atom;

    # print header 
    map { printf $fh "%s\n", $_ } @$option; 
    printf $fh "%s\n\n", $theory; 
    printf $fh "%s\n\n", $title; 
    printf $fh "%d  %d\n", $charge, $spin; 

    # print coordinates 
    for  ( 0..$#labels ) { 
        print_array($fh, '%-3s3%10.3f', $labels[$_], @{$geometry->[$_]}); 
    }

    # connectivity 
    printf $fh "\n"; 

    $fh->close; 

    return; 
} 

# last evaluated expression 
1; 
