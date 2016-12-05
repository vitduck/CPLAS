package VASP::Pseudo; 

use Moose;  
use MooseX::Types::Moose qw/Str ArrayRef/;  
use IO::KISS; 
use Periodic::Table qw( Element Element_Name ); 
use VASP::Types qw/Pseudo/; 
use File::Basename; 
use File::Spec::Functions; 
use namespace::autoclean; 
use experimental qw/signatures/;  

with qw/IO::Reader IO::Cache/; 

# IO::Reader 
has '+input', ( 
    init_arg  => undef, 
    lazy      => 1, 
    builder   => '_build_potcar'
); 

# Native
has 'potcar_dir', ( 
    is        => 'ro', 
    isa       => Str, 
    init_arg  => undef, 
    reader    => 'get_potcar_dir',
    default   => $ENV{ POTCAR_DIR }, 
); 

has 'config', ( 
    is        => 'ro', 
    isa       => ArrayRef[ Str ],
    init_arg  => undef, 
    traits    => [ 'Array' ],
    lazy      => 1, 
    builder   => '_build_config', 
    handles   => { get_configs => 'elements' } 
); 

has 'element', ( 
    is        => 'ro', 
    isa       => Str, 
    required  => 1, 
    reader    => 'get_element'
); 

has 'exchange', ( 
    is        => 'ro', 
    isa       => Pseudo, 
    reader    => 'get_exchange', 
    default   => 'PAW_PBE'
); 

for my $atb ( qw/name valence date/ ) { 
    has $atb, ( 
        is        => 'ro', 
        isa       => Str, 
        init_arg  => undef, 
        lazy      => 1, 
        reader    => 'get_' . $atb, 
        default   => sub { shift->cache->{ $atb } }
    )
}

sub BUILD ( $self, @ ) { 
    # check if potential directory is accessible 
    if ( not -d $self->get_potcar_dir ) { 
        die "Please export the location of POTCAR files in .bashrc\n
        For example: export POTCAR_DIR=/opt/VASP/POTCAR\n";
    }

    # parse POTCAR 
    $self->cache; 
    $self->_clear_reader; 
} 

sub _build_config ( $self ) {  
    return [   
        map basename( $_ ), 
        grep /\/(${ \$self->get_element })(\z|\d|_|\.)/, 
        glob "${ \$self->get_potcar_dir }/${ \$self->get_exchange }/*"
    ]
} 

sub _build_potcar ( $self ) { 
    while ( 1 ) { 
        # prompt 
        printf "=> Pseudopotentials < %s >: ", join(' | ', $self->get_configs );  
        chomp ( my $choice = <STDIN> =~ s/\s+//rg ); 

        if ( grep $choice eq $_ , $self->get_configs ) { 
            return catfile( 
                    $self->get_potcar_dir,
                    $self->get_exchange, 
                    $choice, 
                    'POTCAR' 
            ), 
        }
    }
} 

sub _build_cache ( $self ) { 
    my %cache; 

    for ( $self->get_lines ) { 
        # Ex: VRHFIN =C: s2p2
        if ( /VRHFIN =(\w+)\s*:(.*)/ ) { 
            $cache{ element } = $1; 
            my @split_valences = ( $2 =~ /([spdf]\d+)/g ); 

            # Ex: 3d7 4s2
            $cache{ valence } = 
                @split_valences  
                ? join '', @split_valences 
                : ( split ' ', $2 )[0]; 
        } 
        
        # Ex: TITEL  = PAW_PBE C_s 06Sep2000
        if ( /TITEL/ ) { 
            ( $cache{ pseudo }, $cache{ date } ) = ( split )[3,4]; 
        }

        $cache{ name }   = to_Element_Name( $self->get_element );  
        $cache{ date } //= '---'
    }

    return \%cache
} 

__PACKAGE__->meta->make_immutable;

1
