package VASP::Exchange; 

use MooseX::Types -declare => [ qw/VASP/ ];   
use MooseX::Types::Moose qw/Str/; 

use strictures 2; 
use namespace::autoclean; 

subtype VASP, as Str, where { /PAW_PBE|PAW_GGA|PAW_LDA|POT_GGA|POT_LDA/ }; 
