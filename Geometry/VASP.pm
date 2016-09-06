package Geometry::VASP; 

use Moose::Role; 
use MooseX::Types::Moose qw/Bool Str Int ArrayRef HashRef/; 

use strictures 2; 
use namespace::autoclean; 
use experimental qw/signatures/; 

use Periodic::Table qw/Element/;  

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
    isa       => HashRef, 
    traits    => ['Hash'], 
    lazy      => 1, 
    init_arg  => undef, 

    default   => sub ( $self ) { 
        $self->read('constraint')
    },  

    handles   => { 
        get_constraint    => 'get', 
        set_constraint    => 'set', 
        delete_constraint => 'delete', 
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

1; 
