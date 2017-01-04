package VASP::POSCAR::Geometry;  

use Moose::Role; 
use MooseX::Types::Moose qw/Bool Str Int ArrayRef HashRef/;

use namespace::autoclean; 
use experimental 'signatures';   

with 'General::Geometry';  

has 'version', ( 
    is        => 'ro', 
    isa       => Int,  
    lazy      => 1, 
    reader    => 'get_version', 
    default   => sub { shift->get_cached( 'version' ) }
);  

has 'scaling', ( 
    is        => 'ro', 
    isa       => Str,   
    lazy      => 1, 
    reader    => 'get_scaling', 
    default   => sub { shift->get_cached( 'scaling' ) }
);  

has 'selective', ( 
    is        => 'ro', 
    isa       => Bool,  
    lazy      => 1, 
    reader    => 'get_selective', 
    default   => sub { shift->get_cached( 'selective' ) }
); 

has 'type', ( 
    is        => 'ro', 
    isa       => Str, 
    lazy      => 1, 
    reader    => 'get_type', 
    default   => sub { shift->get_cached( 'type' ) }
); 

has 'dynamics', ( 
    is        => 'rw', 
    isa       => ArrayRef, 
    traits    => [ 'Array' ], 
    lazy      => 1, 
    clearer   => 'clear_dynamics', 
    default   => sub { shift->get_cached( 'dynamics' ) }, 
    handles   => { 
        add_dynamics => 'push',
        get_dynamics => 'elements' 
    },   
); 

has 'index', ( 
    is        => 'ro', 
    isa       => ArrayRef, 
    traits    => [ 'Array' ], 
    lazy      => 1, 
    init_arg  => undef,
    builder   =>  '_build_index', 
    handles   => { get_indices => 'elements' }
); 

for my $atb ( qw/false true/ ) { 
    has "${atb}_index", ( 
        is        => 'ro', 
        isa       => ArrayRef, 
        traits    => [ 'Array' ], 
        lazy      => 1, 
        init_arg  => undef,
        builder   =>  "_build_${atb}_index",  
        handles   => { "get_${atb}_indices" => 'elements' }
    ); 
} 

for my $atb ( qw/atom coordinate dynamics/ ) { 
    has "indexed_${atb}", ( 
        is        => 'ro', 
        isa       => HashRef, 
        traits    => [ 'Hash' ], 
        lazy      => 1, 
        init_arg  => undef,
        clearer   => "clear_indexed_${atb}",
        builder   => "_build_indexed_${atb}",
        handles   => { 
            "delete_indexed_${atb}" => 'delete', 
            "get_indexed_${atb}"    => 'get', 
        } 
    )
}

sub _build_comment ( $self ) { 
    return $self->get_cached( 'comment' )    
} 

sub _build_lattice ( $self ) { 
    return $self->get_cached( 'lattice' )    
}

sub _build_atom ( $self ) { 
    return $self->get_cached( 'atom' )       
}

sub _build_natom ( $self ) { 
    return $self->get_cached( 'natom' )      
} 

sub _build_coordinate ( $self ) { 
    return $self->get_cached( 'coordinate' ) 
} 

sub _build_indexed_atom ( $self ) { 
    my @atoms  = $self->get_atoms; 
    my @natoms = $self->get_natoms; 

    @atoms  = map { ( $atoms[$_] ) x $natoms[$_] } 0..$#atoms;  

    return { map { $_+1 => $atoms[ $_ ] } 0..$#atoms } 
}

# sub _build_indexed_coordinate ( $self ) {
    # my @coordinates = $self->get_coordinates;  
    
    # return { map { $_+1 => $coordinates[ $_ ] } 0..$#coordinates } 
# } 

# sub _build_indexed_dynamics ( $self ) { 
    # my @dynamics = $self->get_dynamics;  

    # return { map { $_+1 => $dynamics[ $_ ] } 0..$#dynamics } 
# } 

# sub _build_natom ( $self ) { 
    # my @natoms;  

    # for my $element ( $self->get_elements ) { 
        # my $natom = (
            # grep $element eq $_, 
            # map  $self->get_atom( $_ ), 
            # $self->get_indices
        # );  
        # push @natoms, $natom; 
    # } 

    # return \@natoms; 
# } 

# sub _build_index ( $self ) { 
    # my  @coordinates =
    # return [ sort { $a <=> $b } $self->get_coordinate_indices ] 
# } 

# sub _build_false_index ( $self ) { 
    # my @f_indices = ();  

    # for my $index ( $self->get_dynamics_indices ) { 
        # # off-set index by 1
        # push @f_indices, $index - 1 
            # if grep $_ eq 'F', $self->get_dynamics( $index )->@*;   
    # }

   # return \@f_indices;  
# } 

# sub _build_true_index ( $self ) {
    # my @t_indices = ();  

    # for my $index ( $self->get_dynamics_indices ) { 
        # # off-set index by 1
        # push @t_indices, $index - 1 
            # if ( grep $_ eq 'T', $self->get_dynamics( $index )->@* ) == 3  
    # }

    # return \@t_indices;  
# }

# sub _build_element ( $self ) { 
    # my @elements;  

    # for my $index ( $self->get_indices ) { 
        # my $element = $self->get_atom( $index ); 

        # next if grep $element eq $_, @elements; 
        # push @elements, $element; 
    # } 

    # return \@elements; 
# } 

1
