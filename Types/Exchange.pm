package Types::Exchange;  

use strict; 
use warnings FATAL => 'all'; 

use MooseX::Types -declare => [ qw( VASP_PP ) ];   
use MooseX::Types::Moose qw( Str );  

subtype VASP_PP, as Str, where { /PAW_PBE|PAW_GGA|PAW_LDA|POT_GGA|POT_LDA/ } 
