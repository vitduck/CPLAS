package VASP::INCAR;  

use Moose;  
use MooseX::Types::Moose qw( Num HashRef );  
use String::Util qw( trim ); 
use namespace::autoclean; 
use experimental qw( signatures ); 

with qw( IO::Reader ); 
with qw( VASP::Spin ); 

has '+input', ( 
    init_arg  => undef,
    default   => 'INCAR' 
);  

has '+cache', ( 
    handles   => { 
        get_tag => 'get'
    }
); 

has '+magmom', ( 
    handles   => { 
        get_init_magmom => 'get'
    }
); 

sub _build_magmom ( $self ) {  
    my @magmom;

    for ( split ' ', $self->get_tag( 'MAGMOM' ) ) { 
        push @magmom, ( 
            /(\d+)\*(.*)/ 
            ? ( $2 ) x $1
            : $_          
        );
    } 

    return { map { $_+1 => $magmom[ $_ ] } 0..$#magmom } 
} 

sub _build_cache ( $self ) { 
    my %incar; 

    while ( defined ( local $_ =  $self->_get_line ) ) { 
        next if $_ eq ''; 
        next if /^\s*#/; 

        # grep in list context
        my ( $key, $value ) = ( /(.*)=(.*)/g ); 

        # trim leading and trailing whitespace
        $incar{ trim( $key ) } = trim ( $value );  
    } 

    return \%incar; 
} 

__PACKAGE__->meta->make_immutable;

1 
