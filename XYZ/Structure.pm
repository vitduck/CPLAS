package XYZ::Structure; 

use Moose; 
use MooseX::Types::Moose qw( Str ); 

use namespace::autoclean; 
use experimental qw( signatures ); 

with qw( XYZ::Geometry );  

has 'file', ( 
    is        => 'ro', 
    isa       => Str, 
    required  => 1, 
); 

1
