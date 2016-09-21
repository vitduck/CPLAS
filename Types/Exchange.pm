package Types::Exchange;  

use strict; 
use warnings FATAL => 'all'; 

use MooseX::Types::Moose 'Str'; 
use MooseX::Types -declare => [ 'VASP_PP' ];   

subtype VASP_PP, as Str, where { /PAW_PBE|PAW_GGA|PAW_LDA|POT_GGA|POT_LDA/ } 
