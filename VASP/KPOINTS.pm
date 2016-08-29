package VASP::KPOINTS; 

# core 
use List::Util qw/product/; 

# cpan
use Moose;  
use MooseX::Types::Moose qw/HashRef Int/; 
use namespace::autoclean; 

# pragma
use autodie; 
use warnings FATAL => 'all'; 
use experimental qw/signatures/; 

# Moose role 
with 'VASP::Parser'; 

# Moose attributes 
has '+file', ( 
    default  => 'KPOINTS', 
); 

has 'read_KPOINTS', ( 
    is       => 'ro', 
    isa      => HashRef, 
    traits   => ['Hash'],  
    init_arg => undef,  
    lazy     => 1, 
    default  => sub ( $self ) { 
        my $kp         = {}; 
        # header 
        $kp->{comment} =   $self->get_line; 
        $kp->{kmode}   =   $self->get_line;  
        $kp->{scheme}  = ( $self->get_line ) =~ /^M/ ? 'Monkhorst-Pack' : 'Gamma-centered';

        # k-mesh 
        if ( $kp->{kmode} == 0 ) { 
            # automatic k-mesh generation 
            $kp->{mesh} = [ map int, map split, $self->get_line ];
        } elsif ( $kp->{kmode} > 0 ) { 
            # maunal k-mesh 
            while ( local $_ = $self->get_line ) {
                push $kp->{mesh}->@*, [(split)[0,1,2]]; 
            }
        } else { 
            # line mode ( band calculation )
            ...
        } 

        # k-shift 
        if ( $kp->{kmode} == 0 ) { 
            $kp->{shift} = [ map split, $self->get_line ]
        }
        return $kp; 
    },   
    handles => { 
        map { $_ => [ get => $_ ] } qw/comment kmode scheme mesh shift/  
    }, 
); 

has 'nkpt', ( 
    is       => 'ro', 
    isa      => Int, 
    init_arg => undef, 
    lazy     => 1, 

    default  => sub ( $self )  { 
        return $self->kmode == 0 ? product($self->mesh->@*) : $self->mode; 
    }
); 

# speed-up object construction 
__PACKAGE__->meta->make_immutable;

1; 
