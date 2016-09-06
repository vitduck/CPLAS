package IO::Parser; 

use Moose::Role; 
use MooseX::Types::Moose qw/Str HashRef/;  

use strictures 2; 
use namespace::autoclean; 
use experimental qw/signatures/;

use IO::KISS; 

requires '_parse_file'; 

has 'parser', ( 
    is        => 'ro', 
    isa       => HashRef, 
    traits    => ['Hash'], 
    lazy      => 1, 
    init_arg  => undef, 
    builder   => '_parse_file', 

    handles   => { 
        read => 'get',  
        list => 'keys', 
    }, 
); 

1; 
