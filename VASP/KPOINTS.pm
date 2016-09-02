package VASP::KPOINTS; 

# core 
use List::Util qw/product/; 

# cpan
use Moose;  
use MooseX::Types::Moose qw/Str Int ArrayRef HashRef/; 
use namespace::autoclean; 

# pragma
use autodie; 
use warnings FATAL => 'all'; 
use experimental qw/signatures/; 

# Moose role 
with qw/IO::Proxy/; 

# From IO::Proxy
has '+file', ( 
    default  => 'KPOINTS', 
); 

has '+parser', ( 
    lazy      => 1,  
    builder   => '_parse_KPOINTS', 
      
); 

# Native
has 'comment', ( 
    is        => 'ro', 
    isa       => Str,  
    init_arg  => undef, 
    lazy      => 1, 
    default   => sub ( $self ) { 
        return $self->parser->{comment} 
    }
); 

has 'mode', ( 
    is        => 'ro', 
    isa       => Int,  
    init_arg  => undef, 
    lazy      => 1, 
    default   => sub ( $self ) { 
        return $self->parser->{mode} 
    }
); 

has 'scheme', ( 
    is        => 'ro', 
    isa       => Str,  
    init_arg  => undef, 
    lazy      => 1, 
    default   => sub ( $self ) { 
        return $self->parser->{scheme} 
    }
); 

has 'grid', ( 
    is       => 'ro', 
    isa      => ArrayRef, 
    traits   => ['Array'], 
    lazy     => 1, 
    default  => sub ( $self ) { 
        return $self->parser->{grid} 
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
        return $self->parser->{shift} 
    },  
    handles  => { 
        get_shifts => 'elements' 
    }, 
); 

has 'nkpt', ( 
    is       => 'ro', 
    isa      => Int, 
    init_arg => undef, 
    lazy     => 1, 
    default  => sub ( $self )  { 
        return $self->mode == 0 ? product($self->get_grids) : $self->mode; 
    }
); 

#----------------#
# Private Method #
#----------------#
sub _parse_KPOINTS ( $self ) { 
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

# speed-up object construction 
__PACKAGE__->meta->make_immutable;

1; 
