package XYZ::Geometry; 

use Moose::Role; 
use Periodic::Table qw( Element );  
use namespace::autoclean; 
use experimental qw( signatures );  

with qw( IO::Reader IO::Cache Geometry::General );  

# from IO::Reader
sub _build_reader ( $self ) { return IO::KISS->new( $self->file, 'r' ) }

# from IO::Cache
sub _build_cache ( $self ) { 
    my %xyz = (); 

    $xyz{total_natom} = $self->get_line; 
    $xyz{comment}     = $self->get_line; 

    my ( @atoms, @coordinates ) = (); 
    while ( local $_ = $self->get_line ) { 
        my ( $atom, $x, $y, $z ) = split; 

        push @atoms, $atom; 
        push @coordinates, [ $x, $y, $z ]; 
    } 

    # indexing 
    $xyz{atom}       = { map { $_+1 => $atoms[$_]       } 0..$#atoms       };   
    $xyz{coordinate} = { map { $_+1 => $coordinates[$_] } 0..$#coordinates };  

    # close internal fh 
    $self->close_reader; 

    return \%xyz 
} 

# from Geometry::General
sub _build_lattice ( $self ) {
    return [ 
        [ 15.0, 0.00, 0.00 ], 
        [ 0.00, 15.0, 0.00 ], 
        [ 0.00, 0.00, 15.0 ]
    ]
}

1
