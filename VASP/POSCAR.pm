package VASP::POSCAR; 

use Moose;  
use MooseX::Types::Moose qw( Str );  
use VASP::POTCAR; 
use Try::Tiny; 
use File::Copy qw( copy ); 
use namespace::autoclean; 
use experimental qw( signatures );  

with qw( IO::Reader IO::Writer ); 
with qw( VASP::POSCAR::Reader ); 
with qw( VASP::POSCAR::Geometry ); 
with qw( VASP::POSCAR::Format ); 

has '+input', ( 
    default   => 'POSCAR' 
); 

has '+output', ( 
    writer    => '_set_output', 
    default   => 'POSCAR'
); 

has 'backup_file', ( 
    is        => 'ro', 
    isa       => Str, 
    init_arg  => undef, 
    lazy      => 1, 
    default   => sub { shift->input.'.old' } 
); 

sub BUILD ( $self, @ ) { 
    # cache POSCAR
    try { $self->cache };  
} 

sub refresh ( $self ) {
    $self->_clear_reader; 
    $self->_clear_writer; 
    $self->_clear_cache; 
} 

sub update ( $self ) { 
    $self->_clear_index; 
    $self->_clear_element; 
    $self->_clear_natom; 
} 

sub backup ( $self, $poscar = $self->backup_file ) { 
    copy $self->file => $poscar
} 

sub delete ( $self, @indices ) { 
    $self->delete_atom( @indices );  
    $self->delete_dynamics( @indices ); 
    $self->delete_coordinate( @indices ); 

    $self->update; 
}

sub freeze ( $self, $dynamics, @indices ) { 
    @indices = @indices ? @indices : $self->get_indices;  
    
    $self->set_dynamics( 
        map { $_ => [ split ' ', $dynamics ] } @indices  
    )  
} 

sub unfreeze ( $self, @indices ) { 
    $self->freeze( 'T T T', @indices ) 
} 

sub write ( $self, $poscar = $self->output ) { 
    $self->_set_output( $poscar ); 

    $self->write_comment; 
    $self->write_scaling; 
    $self->write_lattice; 
    $self->write_element; 
    $self->write_natom; 
    $self->write_selective; 
    $self->write_type; 
    $self->write_coordinate; 

    $self->_close_writer; 
}

__PACKAGE__->meta->make_immutable;

1 
