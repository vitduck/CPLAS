package VASP::STOPCAR;  

use Moose;  
use MooseX::Types::Moose 'Bool'; 

use namespace::autoclean; 
use experimental 'signatures';  

with 'VASP::STOPCAR::IO';  

has '+output', ( 
    default   => 'STOPCAR' 
);  
    
has 'LSTOP' => ( 
    is        => 'ro', 
    isa       => Bool, 
    traits    => [ 'Bool' ], 
    init_arg  => undef, 
    lazy      => 1, 
    default   => 1, 
    handles   => { 
        stop_ionic => 'set'
    }
); 

has 'LABORT' => ( 
    is        => 'ro', 
    isa       => Bool, 
    traits    => [ 'Bool' ], 
    init_arg  => undef, 
    lazy      => 1, 
    default   => 0, 
    handles   => { 
        stop_electronic => 'set'
    }
); 

sub stop ( $self ) { 
   $self->print( 'LSTOP = .TRUE.' )  if $self->LSTOP; 
} 

__PACKAGE__->meta->make_immutable;

1
