package Geometry::XYZ;  

use Moose::Role; 
use MooseX::Types::Moose qw( Int ); 
use namespace::autoclean; 

with qw( Geometry::General ); 

requires qw( _build_total_natom ); 

has 'total_natom', ( 
    is       => 'ro', 
    isa      => Int, 
    lazy     => 1, 
    init_arg => undef, 
    builder  => '_build_total_natom'
); 

1
