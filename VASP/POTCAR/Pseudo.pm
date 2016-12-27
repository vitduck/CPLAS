package VASP::POTCAR::Pseudo;  

use Moose::Role;  
use MooseX::Types::Moose qw/Str ArrayRef/;  
use VASP::Pseudo;  

use namespace::autoclean; 
use experimental 'signatures';  

has 'element', ( 
    is        => 'ro', 
    isa       => ArrayRef, 
    traits    => [ 'Array' ], 
    init_arg  => undef,
    lazy      => 1, 
    builder   => '_build_element', 
    handles   => { get_elements => 'elements' }
); 

has 'potential', ( 
    is        => 'ro', 
    isa       => ArrayRef,  
    traits    => [ 'Array' ], 
    init_arg  => undef,
    lazy      => 1, 
    clearer   => 'clear_potential', 
    builder   => '_build_potential', 
    handles   => { 
        has_potential    => 'count',
        add_potential    => 'push',
        get_potentials   => 'elements' 
    }
); 

sub _build_element ( $self ) { 
    $self->info; 
    
    return $self->get_cached( 'element' )
}  

sub _build_potential ( $self ) { 
    if ( -f $self->get_input ) {  
        my @elements = $self->get_cached( 'element' )->@*; 
        my @configs  = $self->get_cached( 'config'  )->@*;  

        return [ 
            map VASP::Pseudo->new( 
                element => $elements[$_],  
                config  => $configs[$_],
                xc      => $self->get_xc 
            ), 0..$#elements
        ]
    } else {  
        return []
    }
} 

1
