package XYZ::Geometry; 

use Try::Tiny; 

use Moose; 
use MooseX::Types::Moose qw( Str Int ); 
use IO::KISS; 

use namespace::autoclean; 
use experimental qw( signatures ); 

with qw( IO::Reader IO::Cache ); 
with qw( Geometry::General );  
with qw( XYZ::Xmakemol ); 

has 'file', ( 
    is        => 'ro', 
    isa       => Str, 
    required  => 1, 
); 

has 'total_natom', ( 
    is       => 'ro', 
    isa      => Int, 
    lazy     => 1, 
    init_arg => undef, 
    builder  => '_build_total_natom'
); 

sub BUILD ( $self, @ ) { 
    try { $self->cache }
}

# IO::Reader
sub _build_reader ( $self ) { 
    return IO::KISS->new( $self->file, 'r' ) 
}

# IO::Cache
sub _build_cache ( $self ) { 
    my %xyz = (); 

    # remove \n 
    $self->chomp_reader;  

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

    $self->close_reader; 

    return \%xyz 
} 

# Geometry::General 
sub _build_comment    { $_[0]->cache->{'comment'} }
sub _build_atom       { $_[0]->cache->{'atom'} }     
sub _build_coordinate { $_[0]->cache->{'coordinate'} } 
sub _build_lattice    { 
    return [ 
        [ 15.0, 0.00, 0.00 ], 
        [ 0.00, 15.0, 0.00 ], 
        [ 0.00, 0.00, 15.0 ]
    ]
}

# native 
sub _build_total_natom { $_[0]->cache->{'total_natom'} }

1
