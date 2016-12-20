package VASP::INCAR::IO;  

use Moose::Role;  
use String::Util 'trim';  

use namespace::autoclean; 
use experimental 'signatures';  

with 'IO::Reader'; 
with 'IO::Cache';  

sub _build_cache ( $self ) { 
    my %cache; 

    # skip blank and commented line 
    # math key = value pair
    while ( defined( local $_ =  $self->get_line ) ) { 
        if ( $_ eq ''    ) { next } 
        if ( /^\s*#/     ) { next }  
        if ( /(.*)=(.*)/ ) { $cache{ trim( uc( $1 ) ) } = trim( $2 ) } 
    }

    return \%cache 
} 

1 
