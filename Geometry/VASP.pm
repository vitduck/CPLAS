package Geometry::VASP; 

use strict; 
use warnings FATAL => 'all'; 
use feature 'signatures'; 
use namespace::autoclean; 

use Moose::Role; 
use MooseX::Types::Moose 'Bool','Str','Int','ArrayRef','HashRef';  
use Types::Periodic 'Element'; 

no warnings 'experimental'; 

with 'Geometry::General'; 

has 'version', ( 
    is        => 'ro', 
    isa       => Int,  
    lazy      => 1, 
    builder   => '_build_version' 
);  

has 'scaling', ( 
    is        => 'ro', 
    isa       => Str,   
    lazy      => 1, 
    builder   => '_build_scaling' 
);  

has 'selective', ( 
    is        => 'ro', 
    isa       => Bool,  
    lazy      => 1, 
    builder   => '_build_selective'
); 

has 'type', ( 
    is        => 'ro', 
    isa       => Str, 
    lazy      => 1, 
    builder   => '_build_type'
); 

has 'indexed_dynamics', ( 
    is        => 'rw', 
    isa       => HashRef, 
    traits    => [ 'Hash' ], 
    lazy      => 1, 
    init_arg  => undef, 
    builder   => '_build_dynamics', 
    handles   => { 
        set_dynamics         => 'set', 
        get_dynamics_indices => 'keys', 
        get_dynamics         => 'get', 
        delete_dynamics      => 'delete' 
    },   
); 

has 'false_index', ( 
    is        => 'ro', 
    isa       => ArrayRef, 
    traits    => [ 'Array' ], 
    lazy      => 1, 
    init_arg  => undef,
    builder   => '_build_false_index', 
    handles   => { get_false_indices => 'elements' }
); 

has 'true_index', ( 
    is        => 'ro', 
    isa       => ArrayRef, 
    traits    => [ 'Array' ], 
    lazy      => 1, 
    init_arg  => undef,
    builder   => '_build_true_index', 
    handles  => {  get_true_indices => 'elements' } 
);  

# overriding 
sub _build_total_natom ( $self ) { return sum( $self->get_natoms ) }   

# native builder 
sub _build_version   ( $self ) { return $self->read( 'version'   ) }   
sub _build_scaling   ( $self ) { return $self->read( 'scaling'   ) }   
sub _build_selective ( $self ) { return $self->read( 'selective' ) } 
sub _build_type      ( $self ) { return $self->read( 'type'      ) } 
sub _build_dynamics  ( $self ) { return $self->read( 'dynamics'  ) }  

sub _build_false_index ( $self ) { 
    my @f_indices = ();  

    for my $index ( $self->get_dynamics_indices ) { 
        push @f_indices, $index - 1 
            if grep $_ eq 'F', $self->get_dynamics($index)->@*;   
    }

   return \@f_indices;  
} 

sub _build_true_index ( $self ) {
    my @t_indices = ();  

    for my $index ( $self->get_dynamics_indices ) { 
        push @t_indices, $index - 1 
            if ( grep $_ eq 'T', $self->get_dynamics($index)->@* ) == 3  
    }

    return \@t_indices;  
}

1
