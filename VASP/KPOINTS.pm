package VASP::KPOINTS; 

use strict; 
use warnings FATAL => 'all'; 

use List::Util qw( product ); 
use Moose;  
use MooseX::Types::Moose qw( Str Int ArrayRef );  
use IO::KISS; 

use namespace::autoclean; 
use experimental qw( signatures ); 

with qw( IO::Parser ); 

has 'file', ( 
    is       => 'ro', 
    isa      => Str,  
    init_arg => undef, 
    default  => 'KPOINTS', 
); 

has 'comment', ( 
    is        => 'ro', 
    isa       => Str, 
    lazy      => 1, 
    init_arg  => undef, 

    default   => sub ( $self ) { 
        return $self->read( 'comment' ) 
    } 
); 

has 'mode', ( 
    is        => 'ro', 
    isa       => Int,  
    lazy      => 1, 
    init_arg  => undef, 

    default   => sub ( $self ) { 
        return $self->read( 'mode' )
    },
);  

has 'scheme', ( 
    is        => 'ro', 
    isa       => Str,  
    lazy      => 1, 
    init_arg  => undef, 

    default   => sub ( $self ) { 
        return $self->read( 'scheme' )
    }, 
); 

has 'grid', ( 
    is       => 'ro', 
    isa      => ArrayRef, 
    traits   => [ 'Array' ], 
    lazy     => 1, 

    default  => sub ( $self ) { 
        return $self->read( 'grid' ) 
    },  

    handles  => { 
        get_grids => 'elements' 
    }, 
); 

has 'shift', ( 
    is       => 'ro', 
    isa      => ArrayRef, 
    traits   => [ 'Array' ], 
    lazy     => 1, 

    default  => sub ( $self ) { 
        return $self->read( 'shift' ) 
    },  

    handles  => { 
        get_shifts => 'elements' 
    }, 
); 

has 'nkpt', ( 
    is       => 'ro', 
    isa      => Int, 
    lazy     => 1, 
    init_arg => undef, 

    default  => sub ( $self ) { 
        return $self->mode == 0 ? product($self->get_grids) : $self->mode 
    } 
); 

sub _parse_file ( $self ) { 
    my $kp = { }; 
   
    # parsing 
    my $fh = IO::KISS->new( $self->file, 'r' ); 
    
    $kp->{comment} =   $fh->get_line; 
    $kp->{mode}    =   $fh->get_line;  
    $kp->{scheme}  = ( $fh->get_line ) =~ /^M/ ? 'Monkhorst-Pack' : 'Gamma-centered';

    # k-mesh 
    if ( $kp->{mode} == 0 ) { 
        # automatic k-mesh generation 
        $kp->{grid} = [ map int, map split, $fh->get_line ];
    } elsif ( $kp->{mode} > 0 ) { 
        # maunal k-mesh 
        while ( local $_ = $fh->get_line ) {
            push $kp->{grid}->@*, [ (split)[0,1,2] ]; 
        }
    } else { 
        # line mode ( band calculation )
        ...
    } 

    # k-shift 
    if ( $kp->{mode} == 0 ) { 
        $kp->{shift} = [ map split, $fh->get_line ]
    }

    $fh->close;   

    return $kp; 
} 

__PACKAGE__->meta->make_immutable;

1; 
