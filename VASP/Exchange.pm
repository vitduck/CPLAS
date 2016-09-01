package VASP::Exchange; 

# cpan 
use MooseX::Types -declare => [ qw( VASP ) ];   
use MooseX::Types::Moose qw( Str ); 

# pragma 
use autodie; 
use warnings FATAL => 'all'; 

subtype VASP, as Str, where { /PAW_PBE|PAW_GGA|PAW_LDA|POT_GGA|POT_LDA/ }; 
