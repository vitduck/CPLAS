package VASP::POTCAR::IO;  

use Moose::Role;  

use namespace::autoclean; 
use experimental 'signatures';  

with 'IO::Reader'; 
with 'IO::Writer'; 
with 'IO::Cache'; 

sub _build_cache ( $self ) { 
    my %cache; 

    for ( $self->get_lines ) { 
        push $cache{ element }->@*, $1         if /VRHFIN =(\w+):/; 
        push $cache{ config  }->@*, (split)[3] if /TITEL/; 
    } 

    return \%cache
} 

1
