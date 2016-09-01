package VASP::KPOINTS; 

# core 
use List::Util qw(product); 

# cpan
use Moose;  
use MooseX::Types::Moose qw( ArrayRef HashRef Str Int ); 
use namespace::autoclean; 

# pragma
use autodie; 
use warnings FATAL => 'all'; 
use experimental qw( signatures ); 

# Moose role 
with qw( IO::Proxy ); 

# Moose attributes 
# From IO::Proxy
has '+file', ( 
    default  => 'KPOINTS', 
); 

has '+parser', ( 
    default  => sub ( $self ) { 
        my $kp         = {}; 
        # header 
        $kp->{comment} =   $self->get_line; 
        $kp->{mode}    =   $self->get_line;  
        $kp->{scheme}  = ( $self->get_line ) =~ /^M/ ? 'Monkhorst-Pack' : 'Gamma-centered';
        # k-mesh 
        if ( $kp->{mode} == 0 ) { 
            # automatic k-mesh generation 
            $kp->{grid} = [ map int, map split, $self->get_line ];
        } elsif ( $kp->{mode} > 0 ) { 
            # maunal k-mesh 
            while ( local $_ = $self->get_line ) {
                push $kp->{grid}->@*, [(split)[0,1,2]]; 
            }
        } else { 
            # line mode ( band calculation )
            ...
        } 
        # k-shift 
        if ( $kp->{mode} == 0 ) { 
            $kp->{shift} = [ map split, $self->get_line ]
        }
        return $kp; 
    },   
); 

for my $name ( qw/comment mode scheme/ ) { 
    has $name, ( 
        is       => 'ro', 
        isa      => Str, 
        init_arg => undef, 
        lazy     => 1, 
        default  => sub ( $self ) { 
            return $self->extract($name) 
        },   
    ); 
}

for my $name ( qw/grid shift/ ) { 
    has $name, ( 
        is       => 'ro', 
        isa      => ArrayRef, 
        traits   => ['Array'], 
        init_arg => undef, 
        lazy     => 1, 
        default  => sub ( $self ) { 
            return $self->extract($name) 
        },   
        handles => { 
            'get_'.$name     => 'shift', 
            'get_'.$name.'s' => 'elements', 
        }, 
    ); 
}

has 'nkpt', ( 
    is       => 'ro', 
    isa      => Int, 
    init_arg => undef, 
    lazy     => 1, 
    default  => sub ( $self )  { 
        return $self->mode == 0 ? product($self->get_grids) : $self->mode; 
    }
); 

# speed-up object construction 
__PACKAGE__->meta->make_immutable;

1; 
