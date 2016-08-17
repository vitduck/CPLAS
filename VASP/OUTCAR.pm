package VASP::OUTCAR; 

# pragma
use autodie; 
use warnings FATAL => 'all'; 

# cpan
use Moose;  
use namespace::autoclean; 

# features
use experimental qw(signatures); 

# Moose roles 
with 'IO::Read', 'VASP::Force'; 

# Moose attributes 
has 'read_OUTCAR', ( 
    is       => 'ro', 
    isa      => 'Str', 
    init_arg => undef, 

    default  => sub ( $self ) { 
        return $self->slurp('OUTCAR'); 
    }, 
); 

# Moose methods
sub BUILD ( $self, @args ) { 
    $self->read_OUTCAR; 
} 

# speed-up object construction 
__PACKAGE__->meta->make_immutable;

1; 
