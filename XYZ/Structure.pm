package XYZ::Structure; 

use autodie; 
use Moose; 
use MooseX::Types::Moose qw( Str Int ArrayRef HashRef );
use namespace::autoclean; 
use experimental qw( signatures ); 

with qw( XYZ::Geometry );  

has 'file', ( 
    is        => 'ro', 
    isa       => Str, 
    required  => 1, 
); 

1
