package VASP::KPOINTS; 

use Moose;  
use MooseX::Types::Moose qw/Str Int ArrayRef/;  
use List::Util 'product';  

use namespace::autoclean; 
use experimental 'signatures';    

with 'VASP::KPOINTS::IO';  

has '+input', ( 
    default   => 'KPOINTS' 
); 

for my $atb ( qw/comment mode scheme/ ) { 
    has $atb, ( 
        is        => 'ro', 
        isa       => Str, 
        init_arg  => undef, 
        lazy      => 1, 
        reader    => "get_$atb", 
        default   => sub { shift->get_cached( $atb ) } 
    )
}

for my $atb ( qw/grid shift/ ) { 
    has $atb, ( 
        is       => 'ro', 
        isa      => ArrayRef, 
        traits   => [ 'Array' ], 
        init_arg => undef, 
        lazy     => 1, 
        default  => sub { shift->get_cached( $atb ) }, 
        handles  => { "get_${atb}s" => 'elements' } 
    )
} 

has 'nkpt', ( 
    is        => 'ro', 
    isa       => Int, 
    lazy      => 1, 
    init_arg  => undef, 
    reader    => 'get_nkpt',
    default   => sub ( $self ) { 
        return 
            $self->get_mode eq 'automatic' 
            ? product( $self->get_grids )
            : scalar ( $self->get_grids )
    } 
); 

__PACKAGE__->meta->make_immutable;

1 
