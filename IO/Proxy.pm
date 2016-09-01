package IO::Proxy; 

# cpan 
use Moose::Role; 
use MooseX::Types::Moose qw( Str HashRef );  
use namespace::autoclean; 

# pragma 
use autodie; 
use warnings FATAL => 'all'; 
use experimental qw( signatures );

# Moose class
use IO::KISS; 

has 'file', ( 
    is        => 'ro', 
    isa       => Str, 
); 

# delegate I/O to IO::KISS
has 'reader', ( 
    is        => 'ro', 
    isa      => 'IO::KISS', 
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

has 'writer', ( 
    is        => 'ro', 
    isa      => 'IO::KISS', 
    init_arg  => undef, 
    lazy      => 1, 
    default   => sub ( $self ) {  
        return IO::KISS->new($self->file, 'w');  
    },  
    handles   => [ qw/print printf/ ], 
); 

has 'parser', ( 
    is        => 'ro', 
    isa       => HashRef, 
    traits    => ['Hash'],
    init_arg  => undef, 
    lazy      => 1, 
    default   => sub ( $self ) { 
        return {} 
    }, 
    handles   => { 
        keywords => 'keys',  
        extract  => 'get', 
    },   
); 

1; 
