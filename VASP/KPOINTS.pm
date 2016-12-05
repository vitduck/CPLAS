package VASP::KPOINTS; 

use Moose;  
use MooseX::Types::Moose qw/Str Int ArrayRef/;  
use List::Util qw/product/;  
use namespace::autoclean; 
use feature qw/switch/; 
use experimental qw/signatures smartmatch/;    

with qw/IO::Reader IO::Cache/;  

# IO::Reader
has '+input', ( 
    default  => 'KPOINTS' 
); 

# Native
for my $atb ( qw/comment mode scheme/ ) { 
    has $atb, ( 
        is        => 'ro', 
        isa       => Str, 
        init_arg  => undef, 
        lazy      => 1, 
        reader    => 'get_' . $atb,  
        default   => sub { shift->cache->{ $atb } } 
    )
}

for my $atb ( qw/grid shift/ ) { 
    has $atb, ( 
        is       => 'ro', 
        isa      => ArrayRef, 
        traits   => [ 'Array' ], 
        init_arg => undef, 
        lazy     => 1, 
        default  => sub { shift->cache->{ $atb } }, 
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
    
    # mesh shift
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
        : scalar ( $self->get_grids )
    )
} 

__PACKAGE__->meta->make_immutable;

1 
