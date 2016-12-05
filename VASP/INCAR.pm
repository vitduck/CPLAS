package VASP::INCAR;  

use Moose;  
use MooseX::Types::Moose qw/Num Int HashRef/;  
use String::Util qw/trim/;  
use namespace::autoclean; 
use experimental qw/signatures/;  

with qw/IO::Reader IO::Cache/;  
with qw/VASP::Spin/;  

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
    handles   => { get_init_magmom => 'get' }
); 

sub _build_cache ( $self ) { 
    my %incar; 

    # skip blank and commented line 
    # math key = value pair
    while ( defined( local $_ =  $self->get_line ) ) { 
        if ( $_ eq ''    ) { next } 
        if ( /^\s*#/     ) { next }  
        if ( /(.*)=(.*)/ ) { $incar{ trim( uc( $1 ) ) } = trim( $2 ) } 
    }

    return \%incar; 
} 

sub _build_magmom ( $self ) {  
    my @magmom = 
        map { /(\d+)\*(.*)/ ? ( $2 ) x $1 : $_  }
        split ' ', $self->get_magmom_tag( 'MAGMOM' );  

    # return indexed hash
    return { 
        map { $_ + 1 => $magmom[ $_ ] } 
        0..$#magmom 
    }
} 

__PACKAGE__->meta->make_immutable;

1 
