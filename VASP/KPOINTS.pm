package VASP::KPOINTS; 

# core 
use List::Util qw/product/; 

# cpan
use Moose;  
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

has '_parse_KPOINTS', ( 
    is       => 'ro', 
    lazy     => 1, 
    traits   => ['Hash'],  
    init_arg => undef,  

    default  => sub ( $self ) { 
        my $kp    = {}; 
        my @lines = $self->parse->@*; 

        # comment 
        $kp->{comment} = shift @lines; 

        # mode ( automatic|manual|line ) 
        $kp->{kmode}    = shift @lines; 

        # scheme  
        $kp->{scheme}  = 
            ( shift @lines ) =~ /^M/ ? 
            'Monkhorst-Pack' : 
            'Gamma-centered';

        # k-mesh 
        if ( $kp->{kmode} == 0 ) { 
            # automatic k-mesh generation 
            $kp->{mesh} = [ map int, map split, shift @lines ];
        } elsif ( $kp->{kmode} > 0 ) { 
            # maunal k-mesh 
            for ( @lines ) {
                push $kp->{mesh}->@*, [(split)[0,1,2]]; 
            }
        } else { 
            ...
        } 

        # k-shift 
        if ( $kp->{kmode} == 0 ) { 
            $kp->{shift} = [ map split, shift @lines ]
        }

        return $kp; 
    },   

    handles => { 
        map { $_ => [ get => $_ ] } qw/comment kmode scheme mesh shift/  
    }, 
); 

has 'nkpt', ( 
    is       => 'ro', 
    isa      => 'Int', 
    lazy     => 1, 
    init_arg => undef, 

    default  => sub ( $self )  { 
        return 
            $self->kmode == 0 ? 
            product($self->mesh->@*) :  
            $self->mode; 
    }
); 

# speed-up object construction 
__PACKAGE__->meta->make_immutable;

1; 
