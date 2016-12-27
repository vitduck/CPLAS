package Thermo::Fvib; 

use Moose::Role;  
use MooseX::Types::Moose 'Num'; 
use List::Util 'sum'; 

use namespace::autoclean; 
use experimental 'signatures';  

requires 'get_eigenvalues'; 

has 'T', ( 
    is        => 'ro', 
    isa       => Num, 
    required  => 1, 
    reader    => 'get_T', 
); 

has 'kb', ( 
    is        => 'ro', 
    isa       => Num, 
    init_arg  => undef, 
    lazy      => 1, 
    reader    => 'get_kb', 
    default   => '8.6173324E-5'
); 

has 'fvib', ( 
    is        => 'ro', 
    isa       => Num, 
    init_arg  => undef, 
    lazy      => 1, 
    reader    => 'get_fvib', 
    builder   => '_build_fvib'
); 

sub _build_fvib ( $self ) { 
    my $kb     = $self->get_kb; 
    my $T      = $self->get_T; 
    my @eigens = $self->get_eigenvalues; 

    return sum( map $kb *$T*log(1.0-exp((-1e-3*$_)/($kb*$T))), @eigens ); 
} 

1 
