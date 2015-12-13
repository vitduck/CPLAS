package Gaussian; 

use Exporter;  
use IO::File; 

use Util qw( paragraph_file );
use Periodic qw( atomic_number ); 
use Math::Linalg qw( print_array ); 
use XYZ qw( tag_xyz ); 

our @gaussian = qw( read_gaussian print_gaussian );  

our @ISA         = qw( Exporter );;
our @EXPORT      = (); 
our @EXPORT_OK   = ( @gaussian ); 
our %EXPORT_TAGS = (); 

# parse gaussian input
# args 
# -< gaussian input file
# return 
# -> gaussian hash
sub read_gaussian { 
    my ( $file ) = @_;  

    my ( %gaussian, %geometry ) = ();  
    my ( $header, $geometry_block ) = (); 
    
    # paragraph mode
    chomp ( ( $header, $gaussian{name}, $geometry_block ) = paragraph_file($file) );  
    
    # option 
    $gaussian{options} = [ $header =~ /(\%.+?)\n/ ];   

    # theory (no more trailing)
    ( $gaussian{theory} ) = ( $header =~ /(#.+?)$/ );  

    my @lines = split /\n/, $geometry_block;  
    
    # charge, spin and structure 
    @gaussian{qw( charge spin )} = split ' ', shift @lines; 

    # read the xyz block
    for ( @lines ) { 
        my ( $element, $x, $y, $z ) = split; 
        push @{$geometry{$element}}, [ $x, $y, $z ]; 
    }

    # array of elements  
    my @atoms = sort { atomic_number($a) <=> atomic_number($b) } keys %geometry; 

    # array of number of atom per element 
    my @natoms = map scalar(@{$geometry{$_}}), @atoms;  

    # array of geometry 
    my @geometry = map @{$geometry{$_}}, @atoms; 

    # complete gaussian hash 
    @gaussian{qw( atom natom geometry )} = ( \@atoms, \@natoms, \@geometry ); 

    return %gaussian; 
}

# print gaussian input 
# args
# -< hash ref of gaussian 
# -< output file
# return 
# -> null 
sub print_gaussian { 
    my ( $gaussian => $file ); 

    # xyz label 
    my @tags = tag_xyz($gaussian->{atom}, $gaussian->{natom}, [1,1,1]);  

    open my $fh, '>', $file or die "Cannot write to $file\n"; 

    # print header 
    map { printf $fh "%s\n", $_ } @{$gaussian->{options}}; 
    printf $fh "%s\n\n", $gaussian->{theory}; 
    printf $fh "%s\n\n", $gaussian->{name}; 
    printf $fh "%d  %d\n", $gaussian->{charge}, $gaussian->{spin}; 

    # print coordinates 
    for  ( 0..$#tags ) { 
        print_array($fh, '%-3s3%10.3f', $tags[$_], $gaussian->{geometry}[$_]);  
    }

    # connectivity 
    printf $fh "\n"; 

    close $fh; 

    return; 
} 

# last evaluated expression 
1; 
