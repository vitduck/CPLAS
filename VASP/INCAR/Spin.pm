package VASP::INCAR::Spin;  

use Moose::Role;  

use namespace::autoclean; 
use experimental 'signatures';  

with 'General::Spin';  

sub _build_magmom ( $self ) {  
    my @magmom = (
        map { /(\d+)\*(.*)/ ? ( $2 ) x $1 : $_  }
        split ' ', $self->get_magmom_tag( 'MAGMOM' ) 
    ); 

    # return indexed hash
    return { 
        map { $_ + 1 => $magmom[ $_ ] } 
        0..$#magmom 
    }
} 

1 
