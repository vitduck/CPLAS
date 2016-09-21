package XYZ::Structure; 

use autodie; 
use strict; 
use warnings FATAL => 'all'; 
use feature 'signatures';  
use namespace::autoclean; 

use Moose; 
use MooseX::Types::Moose 'Str','Int','ArrayRef','HashRef';

no warnings 'experimental';  

with 'IO::Reader','Geometry::XYZ';  

has 'file', ( 
    is        => 'ro', 
    isa       => Str, 
    required  => 1, 
); 

sub _parse_file ( $self ) { 
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

    return \%xyz 
} 

1
