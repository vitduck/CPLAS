package Geometry::XYZ; 

use strict; 
use warnings FATAL => 'all'; 
use feature 'signatures';  
use namespace::autoclean; 

use Moose::Role; 
use Types::Periodic 'Element'; 

no warnings 'experimental'; 

with 'Geometry::General'; 

# overriding 
sub _build_lattice ( $self ) {
    return [ 
        [ 15.0, 0.00, 0.00 ], 
        [ 0.00, 15.0, 0.00 ], 
        [ 0.00, 0.00, 15.0 ]
    ]
}

1
