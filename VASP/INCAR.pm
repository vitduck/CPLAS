package VASP::INCAR;  

use Moose;  
use MooseX::Types::Moose qw( Num HashRef );  
use namespace::autoclean; 
use experimental qw( signatures ); 

with qw( IO::Reader );  
with qw( VASP::INCAR::Reader ); 

has '+input', ( 
    init_arg  => undef,
    default   => 'INCAR' 
);  

has '+cache', ( 
    handles   => { 
        get_tag => 'get'
    }
); 

has 'magmom', ( 
    is        => 'ro', 
    isa       => HashRef[ Num ], 
    traits    => [ qw( Hash ) ], 
    init_arg  => undef, 
    lazy      => 1, 
    builder   => '_build_magmom', 
    handles   => { 
        get_init_magmom => 'get'
    }
); 

sub _build_magmom ( $self ) {  
    my @magmom;

    for ( split ' ', $self->get_tag( 'MAGMOM' ) ) { 
        push @magmom, ( 
            /(\d+)\*(.*)/ 
            ? ( $2 ) x $1
            : $_          
        );
    } 

    return { map { $_+1 => $magmom[ $_ ] } 0..$#magmom } 
} 

__PACKAGE__->meta->make_immutable;

1 
