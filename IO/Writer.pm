package IO::Writer; 

use strict; 
use warnings FATAL => 'all'; 
use feature 'signatures'; 
use namespace::autoclean; 

use Moose::Role; 

no warnings 'experimental'; 

requires '_build_io_writer'; 

has 'io_writer', (  
    is        => 'ro', 
    isa       => 'IO::KISS', 
    lazy      => 1, 
    builder   => '_build_io_writer', 
    handles   => [ qw( print printf close ) ]
); 

sub _build_io_writer ( $self ) { 
    return IO::KISS->new( $self->file, 'w' )     
} 

1
