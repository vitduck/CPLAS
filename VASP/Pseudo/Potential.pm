package VASP::Pseudo::Potential;  

use Moose::Role;  
use MooseX::Types::Moose qw/Str ArrayRef/;  
use Periodic::Table qw/Element Element_Name/; 
use VASP::Types 'Pseudo'; 
use File::Basename; 

use namespace::autoclean; 
use experimental 'signatures';  

has 'xc', ( 
    is        => 'ro', 
    isa       => Pseudo, 
    lazy      => 1, 
    reader    => 'get_xc', 
    default   => 'PAW_PBE'
); 

has 'element', ( 
    is        => 'ro', 
    isa       => Element, 
    required  => 1, 
    reader    => 'get_element'
); 

has 'available_config', ( 
    is        => 'ro', 
    isa       => ArrayRef, 
    traits    => [ 'Array' ],
    init_arg  => undef,
    lazy      => 1, 
    builder   => '_build_available_config', 
    handles   => { get_available_configs => 'elements' }
); 

has 'config', ( 
    is        => 'rw', 
    isa       => Str, 
    lazy      => 1, 
    reader    => 'get_config', 
    clearer   => 'clear_config',
    builder   => '_build_config'
); 

has 'potcar', ( 
    is        => 'ro', 
    isa       => Str, 
    lazy      => 1, 
    init_arg  => undef,
    reader    => 'get_potcar',
    builder   => '_build_potcar'
); 

for my $atb ( qw/name valence date/ ) { 
    has $atb, ( 
        is        => 'ro', 
        isa       => Str, 
        init_arg  => undef, 
        lazy      => 1, 
        reader    => "get_$atb", 
        default   => sub { shift->get_cached( $atb ) }
    )
}

sub _build_available_config  ( $self ) { 
    return [
        map basename( $_ ), 
        grep /\/(${ \$self->get_element })(\z|\d|_|\.)/, 
        glob "${ \$self->get_potcar_dir }/${ \$self->get_xc }/*" 
    ]
} 

sub _build_config ( $self ) { 
    while ( 1 ) { 
        # prompt 
        printf "Select > %s: ", join(' | ', $self->get_available_configs );  
        chomp ( my $select = <STDIN> =~ s/\s+//rg ); 

        return $select if grep $select eq $_ , $self->get_available_configs 
    }
} 

sub _build_potcar ( $self ) { 
    # its important to remove trailing new line 
    $self->chomp; 
    
    return $self->slurp
} 



1
