package Regex::OUTCAR; 

use Moose::Role; 
use MooseX::Types::Moose qw( RegexpRef ); 
use namespace::autoclean; 
use experimental qw( signatures ); 

# match the force block 
# TODO: is it possible to capture the final three columns 
#       without explicit spliting later ? 
has 'force_regex', ( 
    is        => 'ro', 
    isa       => RegexpRef, 
    lazy      => 1, 
    init_arg  => undef, 
    builder   => '_build_force_regex'
); 

sub _build_force_regex ( $self ) { 
    return 
        qr/
            (?:
                \ POSITION\s+TOTAL-FORCE\ \(eV\/Angst\)\n
                \ -+\n
            )
            (.+?) 
            (?: 
                \ -+\n
            )
        /xs 
} 

1; 
