package VASP::OUTCAR; 

use strict;  
use warnings FATAL => 'all'; 

use Moose;  
use MooseX::Types::Moose qw( Str ); 

use namespace::autoclean; 
use experimental qw( signatures ); 

with qw( VASP::Force VASP::Regex );  

has 'file', ( 
    is        => 'ro', 
    isa       => Str, 
    lazy      => 1, 
    default   => 'OUTCAR' 
); 

# slurp content of OUTCAR to a scalar 
has 'slurp', ( 
    is        => 'ro', 
    isa       => Str, 
    lazy      => 1, 
    init_arg  => undef, 

    default   => sub ( $self ) {  
        return IO::KISS->new( $self->file, 'r' )->get_string; 
    }
); 

__PACKAGE__->meta->make_immutable;

1; 
