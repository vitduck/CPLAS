package VASP::KPOINTS; 

# core 
use List::Util qw/product/; 

# cpan
use Moose;  
use MooseX::Types::Moose qw/ArrayRef HashRef Str Int/; 
use namespace::autoclean; 

# pragma
use autodie; 
use warnings FATAL => 'all'; 
use experimental qw/signatures/; 

# Moose role 
with 'VASP::Parser'; 

# Moose attributes 
# From VASP::Parser
has '+file', ( 
    default  => 'KPOINTS', 
); 

has '+parser', ( 
    lazy     => 1, 
    default  => sub ( $self ) { 
        my $kp         = {}; 
        # header 
        $kp->{comment} =   $self->get_line; 
        $kp->{mode}    =   $self->get_line;  
        $kp->{scheme}  = ( $self->get_line ) =~ /^M/ ? 'Monkhorst-Pack' : 'Gamma-centered';
        # k-mesh 
        if ( $kp->{mode} == 0 ) { 
            # automatic k-mesh generation 
            $kp->{mesh} = [ map int, map split, $self->get_line ];
        } elsif ( $kp->{mode} > 0 ) { 
            # maunal k-mesh 
            while ( local $_ = $self->get_line ) {
                push $kp->{mesh}->@*, [(split)[0,1,2]]; 
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

has 'comment', ( 
    is       => 'ro', 
    isa      => Str, 
    init_arg => undef, 
    lazy     => 1, 
    default  => sub ( $self ) { $self->parse('comment') },   
); 

has 'mode', ( 
    is       => 'ro', 
    isa      => Str, 
    init_arg => undef, 
    lazy     => 1, 
    default  => sub ( $self ) { $self->parse('mode') },   
); 

has 'scheme', ( 
    is       => 'ro', 
    isa      => Str, 
    init_arg => undef, 
    lazy     => 1, 
    default  => sub ( $self ) { $self->parse('comment') },   
); 

has 'mesh', ( 
    is       => 'ro', 
    isa      => ArrayRef, 
    init_arg => undef, 
    lazy     => 1, 
    default  => sub ( $self ) { $self-> parse('mesh') }, 
); 

has 'shift', ( 
    is       => 'ro', 
    isa      => ArrayRef, 
    init_arg => undef, 
    lazy     => 1, 
    default  => sub ( $self ) { $self-> parse('mesh') }, 
); 

has 'nkpt', ( 
    is       => 'ro', 
    isa      => Int, 
    init_arg => undef, 
    lazy     => 1, 
    default  => sub ( $self )  { 
        return $self->mode == 0 ? product($self->mesh->@*) : $self->mode; 
    }
); 

# speed-up object construction 
__PACKAGE__->meta->make_immutable;

1; 
