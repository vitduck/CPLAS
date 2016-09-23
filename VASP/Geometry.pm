package VASP::Geometry; 

use Moose::Role; 
use MooseX::Types::Moose qw( Bool Str Int ArrayRef HashRef );  
use Periodic::Table 'Element'; 

use namespace::autoclean; 
use experimental qw( signatures ); 

with qw( IO::Reader IO::Cache Geometry::General );  

has 'version', ( 
    is        => 'ro', 
    isa       => Int,  
    lazy      => 1, 
    builder   => '_build_version' 
);  

has 'scaling', ( 
    is        => 'ro', 
    isa       => Str,   
    lazy      => 1, 
    builder   => '_build_scaling' 
);  

has 'selective', ( 
    is        => 'ro', 
    isa       => Bool,  
    lazy      => 1, 
    builder   => '_build_selective'
); 

has 'type', ( 
    is        => 'ro', 
    isa       => Str, 
    lazy      => 1, 
    builder   => '_build_type'
); 

has 'indexed_dynamics', ( 
    is        => 'rw', 
    isa       => HashRef, 
    traits    => [ 'Hash' ], 
    lazy      => 1, 
    init_arg  => undef, 
    builder   => '_build_dynamics', 
    handles   => { 
        set_dynamics         => 'set', 
        get_dynamics_indices => 'keys', 
        get_dynamics         => 'get', 
        delete_dynamics      => 'delete' 
    },   
); 

has 'false_index', ( 
    is        => 'ro', 
    isa       => ArrayRef, 
    traits    => [ 'Array' ], 
    lazy      => 1, 
    init_arg  => undef,
    builder   => '_build_false_index', 
    handles   => { 
        get_false_indices => 'elements' 
    }
); 

has 'true_index', ( 
    is        => 'ro', 
    isa       => ArrayRef, 
    traits    => [ 'Array' ], 
    lazy      => 1, 
    init_arg  => undef,
    builder   => '_build_true_index', 
    handles  => {  
        get_true_indices => 'elements' 
    } 
);  

# from IO::Reader 
sub _build_reader ( $self ) { 
    return IO::KISS->new( input => $self->file, mode  => 'r', chomp => 1 ) 
}

# from IO::Cache 
sub _build_cache ( $self ) { 
    my %poscar = ();  

    # header 
    $poscar{comment} = $self->get_line; 
    
    # lattice vectors 
    $poscar{scaling} = $self->get_line; 
    $poscar{lattice}->@* = map [ split ' ', $self->get_line  ], 0..2; 

    # natom and element 
    my ( @natoms, @elements ); 
    my @has_VASP5 = split ' ', $self->get_line; 
    if ( ! grep Element->check($_), @has_VASP5 ) { 
        $poscar{version} = 4; 
        # get elements from POTCAR and synchronize with @natoms
        @elements = VASP::POTCAR->new()->get_elements;  
        @natoms   = @has_VASP5;  
        @elements = splice @elements, 0, scalar(@natoms); 
    } else { 
        $poscar{version} = 5; 
        @elements = @has_VASP5; 
        @natoms   = split ' ', $self->get_line; 
    } 

    # build list of atom
    my @atoms = map { ( $elements[$_] ) x $natoms[$_] } 0..$#elements; 
   
    # selective dynamics 
    my $has_selective = $self->get_line; 
    if ( $has_selective =~ /^\s*S/i ) { 
        $poscar{selective} = 1; 
        $poscar{type}      = $self->get_line; 
    } else { 
        $poscar{selective} = 0; 
        $poscar{type}      = $has_selective; 
    } 

    # coodinate and dynamics
    my ( @coordinates, @dynamics );  
    while ( local $_ = $self->get_line ) { 
        # blank line separate geometry and velocity blocks
        last if /^\s+$/; 
        
        # 1st 3 columns are coordinate 
        # if remaining column is either 0 or 1 (w/o indexing) 
        # the POSCAR contains no selective dynamics block 
        my @columns = split; 
        push @coordinates, [ splice @columns, 0, 3 ];  
        push @dynamics, ( 
            @columns == 0 || @columns == 1 ? 
            [ qw( T T T ) ] :
            [ splice @columns, 0, 3 ]
        ); 
    } 
    
    # indexing 
    $poscar{atom}       = { map { $_+1 => $atoms[$_]       } 0..$#atoms       };   
    $poscar{coordinate} = { map { $_+1 => $coordinates[$_] } 0..$#coordinates };  
    $poscar{dynamics}   = { map { $_+1 => $dynamics[$_]    } 0..$#dynamics    };  
    
    $self->close_reader; 

    return \%poscar; 
} 

# from Geometry::General 
sub _build_total_natom ( $self ) { return sum( $self->get_natoms ) }   

sub _build_version   ( $self ) { return $self->read( 'version' )   }   
sub _build_scaling   ( $self ) { return $self->read( 'scaling' )   }   
sub _build_selective ( $self ) { return $self->read( 'selective' ) } 
sub _build_type      ( $self ) { return $self->read( 'type' )      } 
sub _build_dynamics  ( $self ) { return $self->read( 'dynamics' )  }  

sub _build_false_index ( $self ) { 
    my @f_indices = ();  

    for my $index ( $self->get_dynamics_indices ) { 
        # off-set index by 1
        push @f_indices, $index - 1 
            if grep $_ eq 'F', $self->get_dynamics($index)->@*;   
    }

   return \@f_indices;  
} 

sub _build_true_index ( $self ) {
    my @t_indices = ();  

    for my $index ( $self->get_dynamics_indices ) { 
        # off-set index by 1
        push @t_indices, $index - 1 
            if ( grep $_ eq 'T', $self->get_dynamics($index)->@* ) == 3  
    }

    return \@t_indices;  
}

1
