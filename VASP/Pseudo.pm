package VASP::Pseudo;  

use Moose;  
use MooseX::Types::Moose 'Str';  

use namespace::autoclean; 
use experimental 'signatures';  

with 'VASP::Pseudo::IO';   
with 'VASP::Pseudo::Potential';   

has '+input', ( 
    init_arg  => undef, 
    lazy      => 1, 
    builder   => '_build_input'
); 

has 'potcar_dir', ( 
    is        => 'ro', 
    isa       => Str, 
    init_arg  => undef, 
    lazy      => 1, 
    reader    => 'get_potcar_dir',
    default   => $ENV{ POTCAR_DIR }, 
); 

sub BUILD ( $self, @ ) { 
    if ( not -d $self->get_potcar_dir ) { 
        die "Please export the location of POTCAR files in .bashrc\n
        For example: export POTCAR_DIR=/opt/VASP/POTCAR\n";
    }
} 

sub info ( $self ) { 
    printf "%-10s %-10s %-6s %-10s %-s\n", 
        $self->get_xc,
        $self->get_name, 
        $self->get_config,  
        $self->get_valence, 
        $self->get_date, 
} 

__PACKAGE__->meta->make_immutable;

1
