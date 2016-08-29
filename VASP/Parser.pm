package VASP::Parser; 

# cpan 
use Moose::Role; 
use MooseX::Types::Moose qw/HashRef Str/;  
use namespace::autoclean; 

# pragma 
use autodie; 
use warnings FATAL => 'all'; 
use experimental qw/signatures/;

# Moose class
use IO::KISS; 

has 'file', ( 
    is        => 'ro', 
    isa       => Str, 
    init_arg  => undef, 
); 

# delegate I/O to IO::KISS
has 'io', ( 
    is        => 'ro', 
    does      => 'IO::KISS', 
    init_arg  => undef, 
    lazy      => 1, 
    default   => sub ( $self ) {  
        return IO::KISS->new($self->file, 'r');  
    },  
    handles   => [ 
        qw/slurp/,   
        qw/get_line get_lines/, 
        qw/get_paragraph get_paragraph/, 
    ], 
);  

has 'parser', ( 
    isa       => 'ro', 
    isa       => HashRef, 
    traits    => ['Hash'],
    init_arg  => undef, 
    handles   => { 
        parse   => 'get', 
        keyword => 'keys',  
    },   
); 

1; 
