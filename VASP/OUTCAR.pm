package VASP::OUTCAR; 

use Moose;  
use MooseX::Types::Moose qw( Str );  
use namespace::autoclean; 
use experimental qw( signatures );  

with qw( IO::Reader VASP::Force VASP::Regex ); 

has 'file', ( 
    is        => 'ro', 
    isa       => Str, 
    lazy      => 1, 
    default   => 'OUTCAR' 
); 

# from IO::Reader
sub _build_reader ( $self ) { return IO::KISS->new( $self->file, 'r' ) }

__PACKAGE__->meta->make_immutable;

1 
