package VASP::OUTCAR; 

# pragma
use autodie; 
use warnings FATAL => 'all'; 

# cpan
use Moose;  
use namespace::autoclean; 

# features
use experimental qw/signatures/; 

# Moose class 
use IO::KISS; 

# Moose roles 
with qw/VASP::Force/; 

# Moose attributes 
has 'OUTCAR', ( 
    is       => 'ro',
    isa      => 'IO::KISS', 
    init_arg => undef, 

    default  => sub ( $self ) { 
        return IO::KISS->new('OUTCAR'); 
    }, 

    handles => [ qw/slurp/ ],  
); 

# Moose methods
sub BUILD ( $self, @args ) { 
    $self->OUTCAR; 
} 

# speed-up object construction 
__PACKAGE__->meta->make_immutable;

1; 
