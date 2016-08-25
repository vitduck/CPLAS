package VASP::Parser; 

# cpan 
use Moose::Role; 
use namespace::autoclean; 

# pragma 
use autodie; 
use warnings FATAL => 'all'; 
use experimental qw/signatures/;

use IO::KISS; 

has 'file', ( 
    is        => 'ro', 
    isa       => 'Str', 
    init_arg  => undef, 
); 

has 'mode', ( 
    is        => 'ro', 
    isa       => 'Str', 
    init_arg  => undef, 

    default   => 'line', 
); 

has 'parse', ( 
    is        => 'ro', 
    lazy      => 1, 
    init_arg  => undef, 

    default   => sub ( $self ) { 
        my $io = IO::KISS->new($self->file); 

        return $io->${\$self->mode}; 
    } 
);  

1; 
