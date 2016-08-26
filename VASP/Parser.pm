package VASP::Parser; 

# cpan 
use Moose::Role; 
use MooseX::Types;  
use namespace::autoclean; 

# pragma 
use autodie; 
use warnings FATAL => 'all'; 
use experimental qw/signatures/;

# Moose class
use IO::KISS; 

has 'file', ( 
    is        => 'ro', 
    isa       => 'Str', 
    init_arg  => undef, 
); 

# delegate I/O to IO::KISS
has 'read', ( 
    is        => 'ro', 
    does      => 'IO::KISS', 
    lazy      => 1, 
    init_arg  => undef, 
    default   => sub ( $self ) {  
        return IO::KISS->new($self->file, 'r');  
    },  
    handles   => [ 
        qw/slurp/,   
        qw/get_line get_lines/, 
        qw/get_paragraph get_paragraph/, 
    ], 
);  

1; 
