package VASP::INCAR;  

use Moose;  

use namespace::autoclean; 
use experimental 'signatures';  

with 'VASP::INCAR::IO';  
with 'VASP::INCAR::Spin';  

has '+input', ( 
    default   => 'INCAR' 
);  

has '+cache', ( 
    handles   => { 
        get_magmom_tag => [ get => 'MAGMOM' ], 
        get_mdalgo_tag => [ get => 'MDALGO' ], 
        get_neb_tag    => [ get => 'ICHAIN' ] 
    } 
); 

has '+magmom', ( 
    handles   => { get_init_magmom => 'get' }
); 

__PACKAGE__->meta->make_immutable;

1
