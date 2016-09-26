package VASP::OUTCAR; 

use Moose;  
use MooseX::Types::Moose qw( Str );  

use namespace::autoclean; 
use experimental qw( signatures );  

with qw( IO::Reader VASP::Regex ); 
with qw( VASP::Force ); 

has 'file', ( 
    is        => 'ro', 
    isa       => Str, 
    lazy      => 1, 
    default   => 'OUTCAR' 
); 

has 'POSCAR', ( 
    is        => 'ro', 
    isa       => 'VASP::POSCAR',   
    lazy      => 1, 
    init_arg  => undef, 
    default   => sub { return VASP::POSCAR->new }, 
    handles   => [ qw( get_true_indieces get_false_indices ) ]
); 

# from IO::Reader
sub _build_reader ( $self ) { 
    return IO::KISS->new( $self->file, 'r' ) 
}

__PACKAGE__->meta->make_immutable;

1 
