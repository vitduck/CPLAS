package Thermo::Chempot; 

use Moose::Role;  
use MooseX::Types::Moose qw/Str HashRef/; 
use IO::KISS; 

use namespace::autoclean; 
use experimental 'signatures';  

has 'janaf', ( 
    is        => 'ro',
    isa       => Str, 
    reader    => 'get_janaf'
); 

has 'chemopot', ( 
    is        => 'ro',
    isa       => HashRef, 
    init_arg  => undef, 
    lazy      => 1, 
    builder   => '_build_chempot', 
    handles   => { get_chempot => 'get' }
); 

sub _build_chempot ( $self ) {  
    my ( $H0, %chempot );  

    my $fh = IO::KISS->new( $self->get_janaf, 'r' ); 

    while ( local $_ = $fh->get_line ) { 
        # skip header 
        next unless /^\d+/; 
        
        my ($T, $S, $H) = (split)[0, 2, 4]; 

        # reference enthalpy: 
        if ( $T == 0 ) { 
            $H0 = $H; 
        } else { 
            $chempot{ $T } = ( 1000*( $H - $H0 ) - $S * $T )/ 96486;
        } 
    } 

    $fh->close; 

    return \%chempot
} 

1 
