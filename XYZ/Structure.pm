package XYZ::Structure; 

use Moose; 
use MooseX::Types::Moose qw( Int ); 
use namespace::autoclean; 
use experimental qw( signatures ); 

with qw( IO::Reader ); 
with qw( Geometry::XYZ ); 

has '+inpuf', ( 
    required  => 1, 
); 

sub _build_comment ( $self ) { 
    return $self->_get_cached( 'comment' ) 
}

sub _build_atom ( $self ) { 
    return $self->_get_cached( 'atom' ) 
} 

sub _build_coordinate ( $self ) { 
    return $self->_get_cached( 'coordinate' ) 
} 

sub _build_total_natom ( $self ) { 
    return $self->_get_cached( 'total_natom' )
} 

sub _build_lattice ( $self ) { 
    return [ 
        [ 15.0, 0.00, 0.00 ], 
        [ 0.00, 15.0, 0.00 ], 
        [ 0.00, 0.00, 15.0 ]
    ]
}

sub _build_cache ( $self ) { 
    my %xyz = (); 

    $xyz{ total_natom } = $self->_get_line;  
    $xyz{ comment }     = $self->_get_line; 

    my ( @atoms, @coordinates ) = (); 
    while ( local $_ = $self->_get_line ) { 
        my ( $atom, $x, $y, $z ) = split; 

        push @atoms, $atom; 
        push @coordinates, [ $x, $y, $z ]; 
    } 

    # indexing 
    $xyz{ atom }       = { map { $_+1 => $atoms[$_]       } 0..$#atoms       };   
    $xyz{ coordinate } = { map { $_+1 => $coordinates[$_] } 0..$#coordinates };  

    $self->_close_reader; 

    return \%xyz 
}

1
