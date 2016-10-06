package XYZ::Reader; 

use Moose::Role; 
use namespace::autoclean; 
use experimental qw( signatures ); 

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
