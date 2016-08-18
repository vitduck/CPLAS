package VASP::KPOINTS; 

# pragma
use autodie; 
use warnings FATAL => 'all'; 

# core 
use List::Util qw/product/; 

# cpan
use Moose;  
use namespace::autoclean; 

# features
use experimental qw/signatures/; 

# Moose class 
use IO::KISS; 

# Moose attributes 
has 'KPOINTS', ( 
    is       => 'ro', 
    isa      => 'IO::KISS',  
    lazy     => 1, 
    init_arg => undef, 

    default  => sub ( $self ) { 
        return IO::KISS->new('KPOINTS');  
    },  

    handles => [ qw/get_line get_lines/ ], 
); 

has 'comment', ( 
    is       => 'ro', 
    isa      => 'Str', 
    lazy     => 1, 
    init_arg => undef, 

    default  => sub ( $self ) { 
        return $self->get_line;  
    } 
); 

has 'mode', (  
    is       => 'ro', 
    isa      => 'Int', 
    lazy     => 1, 
    init_arg => undef, 

    default  => sub ( $self ) { 
        return $self->get_line;  
    } 
); 

has 'scheme', (  
    is       => 'ro', 
    isa      => 'Str', 
    lazy     => 1, 
    init_arg => undef, 

    default  => sub ( $self ) { 
        return $self->get_line =~ /^M/ ? 'Monkhorst-Pack' : 'Gamma-centered'; 
    } 
); 

has 'mesh', ( 
    is       => 'ro', 
    lazy     => 1, 
    init_arg => undef, 

    default  => sub ( $self ) { 
        # automatic k-mesh generation ? 
        if ( $self->mode == 0 ) { 
            return [ map int, map split, $self->get_line ]; 
        # manual k-mesh 
        } elsif ( $self->mode > 0 ) {  
            my $k = []; 
            while ( local $_ = $self->get_line ) {   
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
            return [ map split, $self->get_line ]; 
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
    $self->KPOINTS; 
    
    # parsing order 
    for ( qw/comment mode scheme mesh shift/ ) { $self->$_ } 
} 

# speed-up object construction 
__PACKAGE__->meta->make_immutable;

1; 
