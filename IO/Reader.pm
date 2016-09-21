package IO::Reader;

use strict; 
use warnings FATAL => 'all'; 
use namespace::autoclean; 
use feature 'signatures'; 

use Moose::Role; 
use MooseX::Types::Moose 'HashRef'; 
use IO::KISS; 

no warnings 'experimental'; 

has 'io_reader', ( 
    is        => 'ro', 
    isa       => 'IO::KISS', 
    lazy      => 1, 
    builder   => '_build_io_reader', 
    handles   => [ qw( get_line get_lines slurp ) ]
); 

has 'reader', ( 
    is        => 'ro', 
    isa       => HashRef, 
    traits    => [ 'Hash' ], 
    lazy      => 1, 
    init_arg  => undef, 
    builder   => '_parse_file', 
    handles   => { 
        read => 'get',  
    }, 
); 

sub _build_io_reader ( $self ) { 
    return IO::KISS->new( $self->file, 'r' ) 
}

1 
