package VASP::OUTCAR; 

# cpan
use Moose;  
use namespace::autoclean; 

# pragma
use autodie; 
use warnings FATAL => 'all'; 
use experimental qw/signatures/; 

# Moose roles 
with qw/IO::Proxy VASP::Force/;  

# Moose attributes 
has '+file', ( 
    default   => 'OUTCAR' 
); 

# speed-up object construction 
__PACKAGE__->meta->make_immutable;

1; 
