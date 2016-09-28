package VASP::KPOINTS; 

use Moose;  
use MooseX::Types::Moose qw( Str Int ArrayRef );  
use IO::KISS; 

use Try::Tiny; 
use List::Util qw( product );  

use namespace::autoclean; 
use feature qw( switch );  
use experimental qw( signatures smartmatch );  

with qw( IO::Reader IO::Cache );  

has 'file', ( 
    is       => 'ro', 
    isa      => Str,  
    lazy     => 1, 
    init_arg => undef, 
    default  => 'KPOINTS' 
); 

has 'comment', ( 
    is        => 'ro', 
    isa       => Str, 
    lazy      => 1, 
    init_arg  => undef, 
    builder   => '_build_comment' 
); 

has 'mode', ( 
    is        => 'ro', 
    isa       => Int,  
    lazy      => 1, 
    init_arg  => undef, 
    builder   => '_build_mode' 
);  

has 'scheme', ( 
    is        => 'ro', 
    isa       => Str,  
    lazy      => 1, 
    init_arg  => undef, 
    builder   => '_build_scheme' 
); 

has 'grid', ( 
    is       => 'ro', 
    isa      => ArrayRef[ Int ], 
    traits   => [ 'Array' ], 
    lazy     => 1, 
    builder  => '_build_grid', 
    handles  => { 
        get_grids => 'elements' 
    } 
); 

has 'shift', ( 
    is       => 'ro', 
    isa      => ArrayRef[ Str ], 
    traits   => [ 'Array' ], 
    lazy     => 1, 
    builder  => '_build_shift', 
    handles  => { 
        get_shifts => 'elements' 
    } 
); 

has 'nkpt', ( 
    is       => 'ro', 
    isa      => Int, 
    lazy     => 1, 
    init_arg => undef, 
    builder  => '_build_nkpt'
); 

sub BUILD ( $self, @ ) { 
    try { $self->cache } 
} 

# IO::Reader
sub _build_reader ( $self ) { 
    return IO::KISS->new( $self->file, 'r' ) 
}

# IO::Cache
sub _build_cache ( $self ) { 
    my %kp = ();  

    # remove \n
    $self->chomp_reader; 
    
    $kp{ comment } = $self->get_line;   
    $kp{ mode }    = $self->get_line;   
    $kp{ scheme }  = 
        $self->get_line  =~ /^M/ 
        ? 'Monkhorst-Pack' 
        : 'Gamma-centered' ;
    
    given ( $kp{ mode } ) {   
        when ( 0 )      { $kp{ grid } = [ map int, map split, $self->get_line ] }
        when ( $_ > 0 ) { push $kp{ grid }->@*, [ ( split )[ 0..2 ] ] for $self->get_lines } 
        default         { ... } 
    }
    
    $kp{ shift } = [ map split, $self->get_line ] if $kp{ mode } == 0; 

    $self->close_reader;  

    return \%kp; 
} 

# native
sub _build_commnet ( $self ) { 
    return $self->cache->{ 'comment' }
} 

sub _build_mode ( $self ) { 
    return $self->cache->{ 'mode' }
} 

sub _build_scheme ( $self ) { 
    return $self->cache->{ 'scheme' }
} 

sub _build_grid ( $self ) { 
    return $self->cache->{ 'grid' }
} 

sub _build_shift ( $self ) { 
    return $self->cache->{ 'shift' }
} 

sub _build_nkpt ( $self ) {
    return 
        $self->mode == 0 
        ? product($self->get_grids)
        : $self->mode 
}  

__PACKAGE__->meta->make_immutable;

1 
