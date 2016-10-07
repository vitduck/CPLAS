package Geometry::XYZ; 

use Moose::Role; 
use MooseX::Types::Moose qw( Bool Str Int ArrayRef HashRef );
use namespace::autoclean; 
use experimental qw( signatures );  

with qw( Geometry::General );  

has 'total_natom', ( 
    is       => 'ro', 
    isa      => Int, 
    lazy     => 1, 
    init_arg => undef, 
    reader   => 'get_total_natom', 
    builder  => '_build_total_natom'
); 

1
