package VASP::INCAR;  

use String::Util 'trim'; 

use Moose;  
use MooseX::Types::Moose qw( Num Int HashRef );  
use namespace::autoclean; 

use experimental 'signatures';  

with 'IO::Reader'; 
with 'IO::Cache'; 
with 'VASP::Spin'; 

# IO::Reader
has '+input', ( 
    default   => 'INCAR' 
);  

# IO::Cache
has '+cache', ( 
    handles   => { 
        get_magmom_tag => [ get => 'MAGMOM' ], 
        get_mdalgo_tag => [ get => 'MDALGO' ], 
        get_neb_tag    => [ get => 'ICHAIN' ] 
    } 
); 

# VASP::Spin
has '+magmom', ( 
    handles   => { 
        get_init_magmom => 'get'
    }
); 

sub _build_cache ( $self ) { 
    my %incar; 

    while ( defined( local $_ =  $self->get_line ) ) { 
        # skip empty line
        next if $_ eq ''; 

        # skip commented line
        next if /^\s*#/; 

        # tag = value ( in list context ) 
        my ( $key, $value ) = ( /(.*)=(.*)/g ); 

        # trim leading and trailing whitespaces
        $incar{ trim( $key ) } = trim( $value );  
    } 

    return \%incar; 
} 

sub _build_magmom ( $self ) {  
    my @magmom;

    for ( split ' ', $self->get_magmom_tag( 'MAGMOM' ) ) { 
        # expand short-handed notation, i.e. 5*2.0
        push @magmom, ( /(\d+)\*(.*)/ ? ( $2 ) x $1 : $_ );
    } 

    # indexing 
    my %magmom = map { $_ + 1 => $magmom[ $_ ] } 0..$#magmom; 

    return \%magmom
} 

__PACKAGE__->meta->make_immutable;

1 
