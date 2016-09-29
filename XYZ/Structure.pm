package XYZ::Structure; 

use Moose; 
use MooseX::Types::Moose qw( Str Int ); 
use namespace::autoclean; 

use Try::Tiny; 
use IO::KISS; 

use experimental qw( signatures ); 

with qw( IO::Reader IO::Cache ); 
with qw( Geometry::XYZ );   
with qw( XYZ::Xmakemol ); 

has 'file', ( 
    is        => 'ro', 
    isa       => Str, 
    required  => 1, 
); 

sub BUILD ( $self, @ ) { 
    try { $self->cache }
}

# IO::Reader
sub _build_reader ( $self ) { return IO::KISS->new( $self->file, 'r' ) }

# IO::Cache
sub _build_cache ( $self ) { 
    my %xyz = (); 

    # remove \n 
    $self->chomp_reader;  

    $xyz{ total_natom } = $self->get_line;  
    $xyz{ comment }     = $self->get_line; 

    my ( @atoms, @coordinates ) = (); 
    while ( local $_ = $self->get_line ) { 
        my ( $atom, $x, $y, $z ) = split; 

        push @atoms, $atom; 
        push @coordinates, [ $x, $y, $z ]; 
    } 

    # indexing 
    $xyz{ atom }       = { map { $_+1 => $atoms[$_]       } 0..$#atoms       };   
    $xyz{ coordinate } = { map { $_+1 => $coordinates[$_] } 0..$#coordinates };  

    $self->close_reader; 

    return \%xyz 
} 

sub _build_comment     ( $self ) { return $self->cache->{ 'comment' } }
sub _build_total_natom ( $self ) { return $self->cache->{ 'total_natom' } }
sub _build_atom        ( $self ) { return $self->cache->{ 'atom' } }     
sub _build_coordinate  ( $self ) { return $self->cache->{ 'coordinate' } } 

sub _build_lattice ( $self ) { 
    return [ 
        [ 15.0, 0.00, 0.00 ], 
        [ 0.00, 15.0, 0.00 ], 
        [ 0.00, 0.00, 15.0 ]
    ]
}

1
