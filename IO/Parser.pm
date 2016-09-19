package IO::Parser; 

use strict; 
use warnings FATAL => 'all'; 

use Moose::Role; 
use MooseX::Types::Moose qw( HashRef );  
use IO::KISS; 

use namespace::autoclean; 
use experimental qw( signatures );

requires '_parse_file'; 

has 'parser', ( 
    is        => 'ro', 
    isa       => HashRef, 
    traits    => [ 'Hash' ], 
    lazy      => 1, 
    init_arg  => undef, 
    builder   => '_parse_file', 

    handles   => { 
        read => 'get',  
        list => 'keys', 
    }, 
); 

1; 
