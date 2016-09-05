package Geometry::VASP; 

use Moose::Role; 
use MooseX::Types::Moose qw/Bool Str Int ArrayRef/; 

use strictures 2; 
use namespace::autoclean; 
use experimental qw/signatures/; 

use Periodic::Table qw/Element/;  

# Moose attribute 
has 'version',( 
    is        => 'ro', 
    isa       => Int,  
    lazy      => 1, 

    default   => sub ( $self ) {  
        return $self->read('version')
    }
);  

has 'scaling', ( 
    is        => 'ro', 
    isa       => Str,   
    lazy      => 1, 

    default   => sub ( $self ) { 
        return $self->read('scaling') 
    } 
);  

has 'selective', ( 
    is        => 'ro', 
    isa       => Bool,  
    lazy      => 1, 

    default   => sub ( $self ) { 
        return $self->read('selective') 
    } 
); 

has 'type', ( 
    is        => 'ro', 
    isa       => Str, 
    lazy      => 1, 

    default   => sub ( $self ) { 
        return $self->read('type') 
    } 
); 

has 'constraint', ( 
    is        => 'rw', 
    isa       => ArrayRef, 
    traits    => ['Array'], 
    lazy      => 1, 
    init_arg  => undef, 

    default   => sub ( $self ) { 
        $self->read('constraint')
    },  

    handles   => { 
        set_constraint  => 'set', 
        get_constraints => 'elements' 
    },   
); 

has 'false_index', ( 
    is        => 'ro', 
    isa       => ArrayRef, 
    traits    => ['Array'], 
    lazy      => 1, 
    init_arg  => undef,

    default   => sub ( $self ) { 
        my $false = []; 
        for my $index ( $self->get_indices ) { 
            if ( grep $_ eq 'F', $self->constraint->[$index]->@* ) { 
                push $false->@*, $index;  
            }
        }
        return $false  
    },  

    handles   => { 
        get_false_indices => 'elements' 
    }, 
); 

has 'true_index', ( 
    is        => 'ro', 
    isa       => ArrayRef, 
    traits    => ['Array'], 
    lazy      => 1, 
    init_arg  => undef,

    default   => sub ( $self ) { 
        my $true = []; 
        for my $index ( $self->get_indices ) { 
            if ( grep $index eq $_, $self->get_false_indices ) { next } 
            push $true->@*, $index; 
        }
        return $true 
    }, 

    handles   => { 
        get_true_indices => 'elements' 
    },   
);  

has 'dynamics', (   
    is        => 'ro', 
    isa       => ArrayRef, 
    lazy      => 1, 

    default   => sub ( $self )  { 
        return [ qw/T T T/ ] 
    }, 

    trigger   => sub ( $self, @args ) { 
        $self->set_constraint( $_-1, $self->dynamics ) for $self->get_sub_indices;  
    },  
); 

1; 
