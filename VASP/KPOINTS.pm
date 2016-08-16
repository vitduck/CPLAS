package VASP::KPOINTS; 

# pragma
use autodie; 
use warnings FATAL => 'all'; 

# core 
use List::Util qw(product); 

# cpan
use Moose;  
use namespace::autoclean; 

# features
use experimental qw(signatures); 

# Moose roles 
with 'IO::Read'; 

# Moose attributes 
has '_read_KPOINTS', ( 
    is       => 'ro', 
    isa      => 'ArrayRef[Str]', 
    traits   => ['Array'], 
    init_arg => undef, 

    default  => sub ( $self ) { 
        return $self->readline('KPOINTS'); 
    },  
    
    # curried delegation 
    handles  => { 'parse' => 'shift' }
); 

has 'comment', ( 
    is       => 'ro', 
    isa      => 'Str', 
    lazy     => 1, 
    init_arg => undef, 

    default  => sub ( $self ) { 
        return $self->parse; 
    } 
); 

has 'mode', (  
    is       => 'ro', 
    isa      => 'Int', 
    lazy     => 1, 
    init_arg => undef, 

    default  => sub ( $self ) { 
        return int($self->parse); 
    } 
); 

has 'scheme', (  
    is       => 'ro', 
    isa      => 'Str', 
    lazy     => 1, 
    init_arg => undef, 

    default  => sub ( $self ) { 
        return ( 
            $self->parse =~ /^M/ ?  
            'Monkhorst-Pack' : 
            'Gamma-centered'
        ); 
    } 
); 

has 'mesh', ( 
    is       => 'ro', 
    lazy     => 1, 
    init_arg => undef, 

    default  => sub ( $self ) { 
        # automatic k-mesh generation ? 
        if ( $self->mode == 0 ) { 
            return [ map int, map split, $self->parse ]; 
        # manual k-mesh 
        } elsif ( $self->mode > 0 ) {  
            my $k = []; 
            while ( local $_ = $self->parse ) {   
                push $k->@*, [(split)[0,1,2]],
            }
            return $k; 
        # line-mode ( band calculation ) 
        } else { 
            ...
        } 
    } 
); 

has 'shift', ( 
    is       => 'ro', 
    isa      => 'ArrayRef[Str]', 
    lazy     => 1, 
    init_arg => undef, 

    default  => sub ( $self ) { 
        if ( $self->mode == 0 ) {    
            return [ map split, $self->parse ]; 
        } 
    }, 
); 

has 'nkpt', ( 
    is       => 'ro', 
    isa      => 'Int', 
    lazy     => 1, 
    init_arg => undef, 

    default  => sub ( $self )  { 
        # automatic k-mesh generation ? 
        if ( $self->mode == 0 ) {  
            return product($self->mesh->@*); 
        } elsif ( $self->mode > 0 ) { 
            return $self->mode; 
        } else { 
            ...
        } 
    } 
); 

# Moose methods
sub BUILD ( $self, @args ) { 
    # parsing order 
    $self->_read_KPOINTS; 
    $self->comment; 
    $self->mode; 
    $self->scheme; 
    $self->mesh; 
    $self->shift; 
} 

# speed-up object construction 
__PACKAGE__->meta->make_immutable;

1; 
