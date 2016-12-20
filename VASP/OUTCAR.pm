package VASP::OUTCAR; 

use Moose;  

use namespace::autoclean; 
use experimental 'signatures';  

with 'VASP::OUTCAR::IO';  
with 'VASP::OUTCAR::Spin';  
with 'VASP::OUTCAR::Energy';  
with 'VASP::OUTCAR::Phonon';  

has '+input', ( 
    init_arg  => undef,
    default   => 'OUTCAR' 
);  

has '+magmom', ( 
    handles   => { get_final_magmom => 'get' }
); 

__PACKAGE__->meta->make_immutable;

1 
