package VASP::Types; 

use strict; 
use warnings; 
use MooseX::Types::Moose qw/Str/;  
use MooseX::Types -declare => [ qw/Pseudo/ ]; 

subtype Pseudo, as Str, where { /PAW_PBE|PAW_GGA|PAW_LDA|POT_GGA|POT_LDA/ }; 

1
