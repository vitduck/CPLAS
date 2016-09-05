package VASP::KPOINTS; 

use Moose;  
use MooseX::Types::Moose qw/Str Int ArrayRef/;  
use List::Util qw/product/; 

use strictures 2;  
use namespace::autoclean; 
use experimental qw/signatures/; 

with qw/IO::RW/; 

# IO::RW
has '+file', ( 
    default  => 'KPOINTS' 
); 

# Native
has 'comment', ( 
    is        => 'ro', 
    isa       => Str, 
    lazy      => 1, 
    init_arg  => undef, 

    default   => sub ( $self ) { 
        return $self->read('comment') 
    } 
); 

has 'mode', ( 
    is        => 'ro', 
    isa       => Int,  
    lazy      => 1, 
    init_arg  => undef, 

    default   => sub ( $self ) { 
        return $self->read('mode')
    },
);  

has 'scheme', ( 
    is        => 'ro', 
    isa       => Str,  
    lazy      => 1, 
    init_arg  => undef, 

    default   => sub ( $self ) { 
        return $self->read('scheme')
    }, 
); 

has 'grid', ( 
    is       => 'ro', 
    isa      => ArrayRef, 
    traits   => ['Array'], 
    lazy     => 1, 

    default  => sub ( $self ) { 
        return $self->read('grid') 
    },  

    handles  => { 
        get_grids => 'elements' 
    }, 
); 

has 'shift', ( 
    is       => 'ro', 
    isa      => ArrayRef, 
    traits   => ['Array'], 
    lazy     => 1, 

    default  => sub ( $self ) { 
        return $self->read('shift') 
    },  

    handles  => { 
        get_shifts => 'elements' 
    }, 
); 

has 'nkpt', ( 
    is       => 'ro', 
    isa      => Int, 
    lazy     => 1, 
    init_arg => undef, 

    default  => sub ( $self ) { 
        return $self->mode == 0 ? product($self->get_grids) : $self->mode 
    } 
); 

sub _parse_file ( $self ) { 
    my $kp = {}; 
    
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
} 

__PACKAGE__->meta->make_immutable;

1; 
