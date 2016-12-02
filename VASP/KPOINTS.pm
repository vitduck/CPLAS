package VASP::KPOINTS; 

use List::Util 'product'; 

use Moose;  
use MooseX::Types::Moose qw( Str Int ArrayRef );  
use namespace::autoclean; 

use feature 'switch';   
use experimental qw( signatures smartmatch );    

with 'IO::Reader'; 
with 'IO::Cache'; 

# IO::Reader
has '+input', ( 
    default  => 'KPOINTS' 
); 

# Native
has 'comment', ( 
    is        => 'ro', 
    isa       => Str, 
    init_arg  => undef, 
    lazy      => 1, 
    reader    => 'get_commnet', 
    default   => sub ( $self ) { $self->cache->{ 'comment' } } 
); 

has 'mode', ( 
    is        => 'ro', 
    isa       => Str,  
    init_arg  => undef, 
    lazy      => 1, 
    reader    => 'get_mode', 
    default   => sub ( $self ) { $self->cache->{ 'mode' } } 
);  

has 'scheme', ( 
    is        => 'ro', 
    isa       => Str,  
    init_arg  => undef, 
    lazy      => 1, 
    reader    => 'get_scheme', 
    default   => sub ( $self ) { $self->cache->{ 'scheme' } } 
); 

has 'grid', ( 
    is       => 'ro', 
    isa      => ArrayRef, 
    traits   => [ qw( Array ) ], 
    init_arg => undef, 
    lazy     => 1, 
    default  => sub ( $self ) { $self->cache->{ 'grid' } }, 
    handles  => { get_grids => 'elements' } 
); 

has 'shift', ( 
    is        => 'ro', 
    isa       => ArrayRef[ Str ], 
    traits    => [ qw( Array ) ], 
    init_arg  => undef, 
    default   => sub ( $self ) { $self->cache->{ 'shift' } }, 
    handles   => { get_shifts => 'elements' }
); 

has 'nkpt', ( 
    is        => 'ro', 
    isa       => Int, 
    lazy      => 1, 
    init_arg  => undef, 
    builder   => '_build_nkpt'
); 

sub _build_cache ( $self ) { 
    my %kp = ();  

    $kp{ comment } = $self->get_line;   
    $kp{ imode   } = $self->get_line;   
    $kp{ scheme  } = (
        $self->get_line =~ /^M/ 
        ? 'Monkhorst-Pack' 
        : 'Gamma-centered' 
    );

    # kmode  
    given ( $kp{ imode } ) {   
        # automatic k-messh
        when ( 0 ) { 
            $kp{ mode } = 'automatic'; 
            $kp{ grid } = [ 
                map int, 
                map split, 
                $self->get_line 
            ] 
        }

        # manual k-mesh 
        when ( $_ > 0 ) { 
            $kp{ mode } = 'manual'; 
            $kp{ grid } = [ 
                map [ ( split )[0..2] ],  
                $self->get_lines 
            ]
        } 

        # line mode ( band calculation ) 
        # TBI 
        default { 
            $kp{ mode } = 'line'
        }
    }
    
    $kp{ shift } = (
        $kp{ imode } == 0 
        ? [ split ' ', $self->get_line ]
        : [ 0, 0, 0 ]
    ); 
    
    return \%kp; 
} 

sub _build_nkpt ( $self ) { 
    return (
        $self->get_mode eq 'automatic' 
        ? product( $self->get_grids )
        : scalar  ( $self->get_grids )
    )
} 

__PACKAGE__->meta->make_immutable;

1 
