package VASP::KPOINTS::Reader; 

use Moose::Role; 
use namespace::autoclean; 
use feature qw( switch );  
use experimental qw( signatures smartmatch );    

sub _build_cache ( $self ) { 
    my %kp = ();  

    $kp{ comment } = $self->_get_line;   
    $kp{ mode }    = $self->_get_line;   
    $kp{ scheme }  = 
        $self->_get_line  =~ /^M/ 
        ? 'Monkhorst-Pack' 
        : 'Gamma-centered' ;
    
    given ( $kp{ mode } ) {   
        when ( 0 )      { $kp{ grid } = [ map int, map split, $self->_get_line ] }
        when ( $_ > 0 ) { push $kp{ grid }->@*, [ ( split )[ 0..2 ] ] for $self->_get_lines } 
        default         { ... } 
    }

    $kp{ shift } = [ map split, $self->_get_line ] if $kp{ mode } == 0;  

    $self->_close_reader;  

    return \%kp; 
} 

1
