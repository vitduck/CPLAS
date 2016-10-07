package VASP::INCAR::Reader; 

use Moose::Role; 
use String::Util qw( trim );  
use namespace::autoclean; 
use experimental qw( signatures );  

sub _build_cache ( $self ) { 
    my %incar; 

    while ( defined ( local $_ =  $self->_get_line ) ) { 
        next if $_ eq ''; 
        next if /^\s*#/; 

        # grep in list context
        my ( $key, $value ) = ( /(.*)=(.*)/g ); 

        # trim leading and trailing whitespace
        $incar{ trim( $key ) } = trim ( $value );  
    } 

    return \%incar; 
}

1
