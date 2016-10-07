package VASP::KPOINTS; 

use Moose;  
use MooseX::Types::Moose qw( Str Int ArrayRef );  
use List::Util qw( product );  
use namespace::autoclean; 
use feature qw( switch );  
use experimental qw( signatures smartmatch );    

with qw( IO::Reader ); 

has '+input', ( 
    default  => 'KPOINTS' 
); 

has 'comment', ( 
    is        => 'ro', 
    isa       => Str, 
    lazy      => 1, 
    init_arg  => undef, 
    default   => sub { $_[0]->_get_cached( 'comment' ) }
); 

has 'mode', ( 
    is        => 'ro', 
    isa       => Int,  
    lazy      => 1, 
    init_arg  => undef, 
    default   => sub { $_[0]->_get_cached( 'mode' ) }
);  

has 'scheme', ( 
    is        => 'ro', 
    isa       => Str,  
    lazy      => 1, 
    init_arg  => undef, 
    default   => sub { $_[0]->_get_cached( 'scheme' ) }
); 

has 'grid', ( 
    is       => 'ro', 
    isa      => ArrayRef[ Int ], 
    traits   => [ qw( Array ) ], 
    lazy     => 1, 
    default  => sub { $_[0]->_get_cached( 'grid' ) }, 
    handles  => { _get_grids => 'elements' } 
); 

has 'shift', ( 
    is       => 'ro', 
    isa      => ArrayRef[ Str ], 
    traits   => [ qw( Array ) ], 
    lazy     => 1, 
    default   => sub { $_[0]->_get_cached( 'shift' ) }, 
); 

has 'nkpt', ( 
    is       => 'ro', 
    isa      => Int, 
    lazy     => 1, 
    init_arg => undef, 
    default  => sub ( $self ) { 
        return 
            $self->mode == 0 
            ? product( $self->_get_grids )
            : $self->mode 
    } 
); 

sub _build_cache ( $self ) { 
    my %kp = ();  

    $kp{ comment } = $self->_get_line;   
    $kp{ mode }    = $self->_get_line;   
    $kp{ scheme }  = 
        $self->_get_line  =~ /^M/ 
        ? 'Monkhorst-Pack' 
        : 'Gamma-centered' ;
    
    given ( $kp{ mode } ) {   
        when ( 0 )      { $kp{ grid } = [ map int, map split, $self->_get_line ] }
        when ( $_ > 0 ) { push $kp{ grid }->@*, [ ( split )[ 0..2 ] ] for $self->_get_lines } 
        default         { ... } 
    }

    $kp{ shift } = [ map split, $self->_get_line ] if $kp{ mode } == 0;  

    $self->_close_reader;  

    return \%kp; 
} 

__PACKAGE__->meta->make_immutable;

1 
