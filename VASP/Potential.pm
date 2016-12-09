package VASP::Potential;  

use Moose;  
use MooseX::Types::Moose qw/Str ArrayRef/;  
use IO::KISS; 
use Periodic::Table qw/Element Element_Name/; 
use VASP::Types 'Pseudo'; 
use File::Basename; 
use File::Spec::Functions; 

use namespace::autoclean; 
use experimental 'signatures';  

with 'IO::Reader';  
with 'IO::Cache'; 

# IO::Reader 
has '+input', ( 
    init_arg  => undef, 
    lazy      => 1, 
    builder   => '_build_input'
); 

# Native
has 'potcar_dir', ( 
    is        => 'ro', 
    isa       => Str, 
    init_arg  => undef, 
    lazy      => 1, 
    reader    => 'get_potcar_dir',
    default   => $ENV{ POTCAR_DIR }, 
); 

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
    writer    => 'set_config',
    default   => '', 
); 

has 'potcar', ( 
    is        => 'ro', 
    isa       => Str, 
    lazy      => 1, 
    init_arg  => undef,
    reader    => 'get_potcar',
    default   => sub { shift->slurp } 
); 

for my $atb ( qw/name valence date/ ) { 
    has $atb, ( 
        is        => 'ro', 
        isa       => Str, 
        init_arg  => undef, 
        lazy      => 1, 
        reader    => 'get_' . $atb, 
        default   => sub { shift->get_cached( $atb ) }
    )
}

sub BUILD ( $self, @ ) { 
    if ( not -d $self->get_potcar_dir ) { 
        die "Please export the location of POTCAR files in .bashrc\n
        For example: export POTCAR_DIR=/opt/VASP/POTCAR\n";
    }
} 

sub info ( $self ) { 
    printf "%-10s %-10s %-6s %-10s %-s\n", 
        $self->get_xc,
        $self->get_name, 
        $self->get_config,  
        $self->get_valence, 
        $self->get_date, 
} 

sub select ( $self ) { 
    while ( 1 ) { 
        # prompt 
        printf "Select > %s: ", join(' | ', $self->get_available_configs );  
        chomp ( my $select = <STDIN> =~ s/\s+//rg ); 

        if ( grep $select eq $_ , $self->get_available_configs ) { 
            $self->set_config( $select ); 
            last; 
        }
    }
} 

sub _build_input ( $self ) { 
    return catfile( 
        $self->get_potcar_dir,
        $self->get_xc, 
        $self->get_config,  
        'POTCAR' 
    ), 
} 

sub _build_available_config  ( $self ) { 
    return [
        map basename( $_ ), 
        grep /\/(${ \$self->get_element })(\z|\d|_|\.)/, 
        glob "${ \$self->get_potcar_dir }/${ \$self->get_xc }/*" 
    ]
} 

sub _build_cache ( $self ) { 
    my %cache; 

    # fh to slurped POTCAR
    my $io = IO::KISS->new( 
        string => \ $self->get_potcar, 
        mode   => 'r', 
    ); 

    for ( $io->get_lines ) { 
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
            @cache{ qw/xc config date/ } = ( split )[2,3,4]; 
            last
        }
    }
    
    $cache{ name }   = to_Element_Name( $self->get_element );  
    $cache{ date } //= '---'; 

    $io->close; 

    return \%cache
} 

__PACKAGE__->meta->make_immutable;

1
