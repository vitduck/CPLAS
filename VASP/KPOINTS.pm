package VASP::KPOINTS; 

use Moose;  
use MooseX::Types::Moose qw( Str Int ArrayRef );  
use List::Util 'product'; 
use namespace::autoclean; 
use feature 'switch';   
use experimental qw( signatures smartmatch );    

with 'IO::Reader'; 

has '+input', ( 
    default  => 'KPOINTS' 
); 

# native
has 'comment', ( 
    is        => 'rw', 
    isa       => Str, 
    init_arg  => undef, 
); 

has 'mode', ( 
    is        => 'rw', 
    isa       => Int,  
    init_arg  => undef, 
);  

has 'scheme', ( 
    is        => 'rw', 
    isa       => Str,  
    init_arg  => undef, 
); 

has 'grid', ( 
    is       => 'rw', 
    isa      => ArrayRef[ Int ], 
    init_arg  => undef, 
    traits   => [ qw( Array ) ], 
    handles  => { 
        get_grids => 'elements' 
    } 
); 

has 'shift', ( 
    is        => 'rw', 
    isa       => ArrayRef[ Str ], 
    init_arg  => undef, 
    traits    => [ qw( Array ) ], 
    handles  => { 
        get_shifts => 'elements' 
    } 
); 

has 'nkpt', ( 
    is        => 'ro', 
    isa       => Int, 
    lazy      => 1, 
    init_arg  => undef, 
    builder   => '_build_nkpt'
); 

sub BUILD ( $self, @ ) { 
    $self->parse
}

sub parse ( $self ) { 
    $self->comment( $self->_get_line );  
    $self->mode   ( $self->_get_line );  
    $self->scheme (  
        $self->_get_line  =~ /^M/ 
            ? 'Monkhorst-Pack' 
            : 'Gamma-centered'
    ); 
    
    given ( $self->mode ) {   
        when ( 0 )      { $self->grid( [ map int, map split, $self->_get_line ] )         }
        when ( $_ > 0 ) { $self->grid( [ map [ ( split )[ 0..2 ] ], $self->_get_lines ] ) } 
        # TBI
        default         { ... } 
    }

    $self->shift( [ map split, $self->_get_line ] ) if $self->mode == 0; 

    $self->_close_reader;  
} 

sub _build_nkpt ( $self ) { 
    return (
        $self->mode == 0 
            ? product( $self->get_grids )
            : $self->mode 
    )
} 

__PACKAGE__->meta->make_immutable;

1 
