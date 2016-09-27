package VASP::Geometry; 

use Moose::Role; 
use MooseX::Types::Moose qw( Bool Str Int ArrayRef HashRef );  
use Periodic::Table 'Element'; 

use namespace::autoclean; 
use experimental qw( signatures ); 

requires qw( cache ); 

has 'version', ( 
    is        => 'ro', 
    isa       => Int,  
    lazy      => 1, 
    default   => sub { $_[0]->cache->{'version'} } 
);  

has 'scaling', ( 
    is        => 'ro', 
    isa       => Str,   
    lazy      => 1, 
    default   => sub { $_[0]->cache->{'scaling'} } 
);  

has 'selective', ( 
    is        => 'ro', 
    isa       => Bool,  
    lazy      => 1, 
    default   => sub { $_[0]->cache->{'selective'} } 
); 

has 'type', ( 
    is        => 'ro', 
    isa       => Str, 
    lazy      => 1, 
    default   => sub { $_[0]->cache->{'type'} } 
); 

has 'indexed_dynamics', ( 
    is        => 'rw', 
    isa       => HashRef, 
    traits    => [ 'Hash' ], 
    lazy      => 1, 
    init_arg  => undef, 
    default   => sub { $_[0]->cache->{'dynamics'} }, 
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
    default   =>  '_build_false_index', 
    handles   => { 
        get_false_indices => 'elements' 
    }
); 

has 'true_index', ( 
    is        => 'ro', 
    isa       => ArrayRef, 
    traits    => [ 'Array' ], 
    lazy      => 1, 
    init_arg  => undef,
    builder   => '_build_true_index', 
    handles  => {  
        get_true_indices => 'elements' 
    } 
);  

sub _build_false_index ( $self ) { 
    my @f_indices = ();  

    for my $index ( $self->get_dynamics_indices ) { 
        # off-set index by 1
        push @f_indices, $index - 1 
            if grep $_ eq 'F', $self->get_dynamics($index)->@*;   
    }

   return \@f_indices;  
} 

sub _build_true_index ( $self ) {
    my @t_indices = ();  

    for my $index ( $self->get_dynamics_indices ) { 
        # off-set index by 1
        push @t_indices, $index - 1 
            if ( grep $_ eq 'T', $self->get_dynamics($index)->@* ) == 3  
    }

    return \@t_indices;  
}


1
