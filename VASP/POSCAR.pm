package VASP::POSCAR; 

use Moose;  
use MooseX::Types::Moose qw/Str HashRef/;  
use Periodic::Table 'Element';  
use VASP::POTCAR; 
use File::Copy 'copy'; 

use namespace::autoclean; 
use experimental qw/signatures smartmatch/;  

with 'IO::Reader';  
with 'IO::Writer'; 
with 'IO::Cache';  

with 'VASP::POSCAR::Geometry';  
# with 'Format::POSCAR'; 

has '+input', ( 
    default   => 'POSCAR' 
); 

has '+output', ( 
    default   => 'POSCAR'
); 

# native
# has 'backup_file', ( 
    # is        => 'ro', 
    # isa       => Str, 
    # init_arg  => undef, 
    # lazy      => 1, 
    # default   => sub { shift->input.'.old' } 
# ); 

# has 'poscar_format', ( 
    # is       => 'ro', 
    # isa      => HashRef, 
    # traits   => [ qw( Hash ) ],  
    # lazy     => 1, 
    # init_arg => undef, 
    # builder  => '_build_format', 
    # handles  => { get_format => 'get' }  
# ); 

# sub refresh ( $self ) {
    # $self->_clear_reader; 
    # $self->_clear_writer; 
    # $self->_clear_cache; 
# } 

# sub update ( $self ) { 
    # $self->_clear_index; 
    # $self->_clear_element; 
    # $self->_clear_natom; 
# } 

# sub backup ( $self, $poscar = $self->backup_file ) { 
    # copy $self->file => $poscar
# } 

# sub delete ( $self, @indices ) { 
    # $self->delete_atom( @indices );  
    # $self->delete_dynamics( @indices ); 
    # $self->delete_coordinate( @indices ); 

    # $self->update; 
# }

# sub freeze ( $self, $dynamics, @indices ) { 
    # @indices = @indices ? @indices : $self->get_indices;  
    
    # $self->set_dynamics( 
        # map { $_ => [ split ' ', $dynamics ] } @indices  
    # )  
# } 

# sub unfreeze ( $self, @indices ) { 
    # $self->freeze( 'T T T', @indices ) 
# } 

# sub write ( $self, $poscar = $self->output ) { 
    # $self->_set_output( $poscar ); 

    # $self->write_comment; 
    # $self->write_scaling; 
    # $self->write_lattice; 
    # $self->write_element; 
    # $self->write_natom; 
    # $self->write_selective; 
    # $self->write_type; 
    # $self->write_coordinate; 

    # $self->_close_writer; 
# }

# sub write_comment ( $self ) { 
    # $self->_printf( "%s\n" , $self->get_comment ) 
# }

# sub write_scaling ( $self ) { 
    # $self->_printf( $self->get_format( 'scaling' ), $self->get_scaling ) 
# } 

# sub write_lattice ( $self ) { 
    # for ( $self->get_lattices ) {  
        # $self->_printf( $self->get_format( 'lattice' ), @$_ ) 
    # }
# }  

# sub write_element ( $self ) { 
    # if ( $self->get_version == 5 ) { 
        # $self->_printf( $self->get_format( 'element' ), $self->get_elements )
    # }
# }

# sub write_natom ( $self ) { 
    # $self->_printf( $self->get_format( 'natom' ), $self->get_natoms )
# }

# sub write_selective ( $self ) { 
    # $self->_printf( "%s\n", 'Selective Dynamics' ) if $self->get_selective;  
# }

# sub write_type ( $self ) { 
    # $self->_printf( "%s\n", $self->get_type )
# } 

# sub write_coordinate ( $self ) { 
    # my $format = $self->get_format( 'coordinate' ); 

    # for ( sort { $a <=> $b } $self->get_indices ) {  
        # $self->get_selective 
        # ? $self->_printf( 
            # $format, 
            # $self->get_coordinate( $_ )->@*, 
            # $self->get_dynamics( $_ )->@*, 
            # $_ 
        # )
        # : $self->_printf( 
            # $format, 
            # $self->get_coordinate( $_ )->@*, 
            # $_ 
        # )   
    # }
# } 

sub _build_cache ( $self ) { 
    my %cache; 

    $cache{ comment } = $self->get_line; 
    $cache{ scaling } = $self->get_line; 
    $cache{ lattice } = [ map [ split ' ', $self->get_line ], 0..2 ]; 

    my @atoms = split ' ', $self->get_line; 
    if ( ! grep Element->check( $_ ), @atoms ) { 
        $cache{ version } = 4; 
        $cache{ atom    } = [ VASP::POTCAR->new->get_elements ];  
        $cache{ natom   } = [ @atoms ];  

        # trim atoms if neccessary 
        $cache{ atom }->@* = splice $cache{ atom }->@*, 0, scalar( @atoms );  
    } else { 
        $cache{ version } = 5; 
        $cache{ atom    } = [ @atoms ]; 
        $cache{ natom   } = [ split ' ', $self->get_line ];  

        # sanity checks 
        my @atoms_from_potcar = VASP::POTCAR->new->get_elements;  
        die "Mismatch betwen POSCAR and POTCAR!\n" 
            unless @atoms ~~ @atoms_from_potcar;  
    } 

    # selective dynamics 
    my $selective = $self->get_line; 
    if ( $selective =~ /^\s*S/i ) { 
        $cache{ selective } = 1; 
        $cache{ type }      = $self->get_line; 
    } else { 
        $cache{ selective } = 0; 
        $cache{ type }      = $selective; 
    } 

    # coodinate and dynamics
    while ( defined( local $_ = $self->get_line ) ) { 
        # blank line separating geometry and velocity
        last if /^\s+$/; 
        
        # determine number of column
        my @columns = split; 

        # coordinate 
        push $cache{ 'coordinate' }->@*, [ splice @columns, 0, 3 ];  

        # remainig column: 
        # - O: not indexed
        # - 1: indexed
        push $cache{ 'dynamics' }->@*,  
            @columns == 0 || @columns == 1
            ? [ qw( T T T ) ] 
            : [ splice @columns, 0, 3 ]
    } 
   
    return \%cache; 
}

__PACKAGE__->meta->make_immutable;

1 
