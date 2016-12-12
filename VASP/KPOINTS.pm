package VASP::KPOINTS; 

use Moose;  
use MooseX::Types::Moose qw/Str Int ArrayRef/;  
use List::Util 'product';  

use namespace::autoclean; 
use feature 'switch';  
use experimental qw/signatures smartmatch/;    

with 'IO::Reader'; 
with 'IO::Cache';  

# IO::Reader
has '+input', ( 
    default   => 'KPOINTS' 
); 

# Native
for my $atb ( qw/comment mode scheme/ ) { 
    has $atb, ( 
        is        => 'ro', 
        isa       => Str, 
        init_arg  => undef, 
        lazy      => 1, 
        reader    => 'get_' . $atb,  
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
        handles  => { 'get_' . $atb . 's' => 'elements' } 
    )
} 

has 'nkpt', ( 
    is        => 'ro', 
    isa       => Int, 
    lazy      => 1, 
    init_arg  => undef, 
    reader    => 'get_nkpt',
    builder   => '_build_nkpt'
); 

sub _build_cache ( $self ) { 
    my %cache = ();  

    $cache{ comment } = $self->get_line;   
    $cache{ imode   } = $self->get_line;   
    $cache{ scheme  } = (
        $self->get_line =~ /^M/ 
        ? 'Monkhorst-Pack' 
        : 'Gamma-centered' 
    );

    # kmode  
    given ( $cache{ imode } ) {   
        # automatic k-messh
        when ( 0 ) { 
            $cache{ mode } = 'automatic'; 
            $cache{ grid } = [ 
                map int, 
                map split, 
                $self->get_line 
            ] 
        }

        # manual k-mesh 
        when ( $_ > 0 ) { 
            $cache{ mode } = 'manual'; 
            $cache{ grid } = [ 
                map [ ( split )[0..2] ],  
                $self->get_lines 
            ]
        } 

        # line mode ( band calculation ) 
        # TBI 
        default { 
            $cache{ mode } = 'line'
        }
    }
    
    # mesh shift
    $cache{ shift } = (
        $cache{ imode } == 0 
        ? [ split ' ', $self->get_line ]
        : [ 0, 0, 0 ]
    ); 
    
    return \%cache; 
} 

sub _build_nkpt ( $self ) { 
    return (
        $self->get_mode eq 'automatic' 
        ? product( $self->get_grids )
        : scalar ( $self->get_grids )
    )
} 

__PACKAGE__->meta->make_immutable;

1 
