package VASP::POTCAR; 

use Moose;  
use MooseX::Types::Moose qw( Str ArrayRef ); 
use Moose::Util::TypeConstraints qw( enum );  
use IO::KISS;  
use Periodic::Table qw( Element Element_Name ); 

use File::Basename; 
use File::Spec::Functions; 

use namespace::autoclean; 
use feature qw( signatures refaliasing );  
use experimental qw( signatures refaliasing ); 

with qw( IO::Reader IO::Writer IO::Cache ); 

has 'pot_dir', ( 
    is        => 'ro', 
    isa       => Str, 
    lazy      => 1, 
    init_arg  => undef, 
    default   => $ENV{POT_DIR}, 
); 

has 'file', ( 
    is        => 'ro', 
    isa       => Str, 
    lazy      => 1, 
    init_arg  => undef, 
    default   => 'POTCAR', 
); 

has 'element', ( 
    is        => 'ro', 
    isa       => ArrayRef[ Element ],  
    traits    => [ 'Array' ], 
    lazy      => 1, 
    default   => sub { [ map $_->[0], $_[0]->get_pp_info ] }, 
    handles   => { 
        get_elements => 'elements' 
    } 
); 

has 'exchange', ( 
    is        => 'ro', 
    isa       => enum( [ qw( PAW_PBE PAW_GGA PAW_LDA POT_GGA POT_LDA ) ] ),  
    lazy      => 1, 
    default   => sub { ( keys $_[0]->cache->%* )[0] } 
); 

has 'pp_info', (  
    is        => 'ro', 
    isa       => ArrayRef, 
    traits    => [ 'Array' ], 
    lazy      => 1, 
    default   => sub { $_[0]->cache->{ $_[0]->exchange } }, 
    handles   => { 
        get_pp_info => 'elements' 
    } 
); 

has 'config', ( 
    is        => 'ro', 
    isa       => ArrayRef, 
    traits    => [ 'Array' ], 
    lazy      => 1, 
    init_arg  => undef, 
    builder   => '_build_config', 
    handles   => { 
        get_configs => 'elements' 
    } 
); 

has 'potcar', ( 
    is        => 'ro', 
    isa       => ArrayRef[ Str ], 
    traits    => [ 'Array' ], 
    lazy      => 1, 
    init_arg  => undef, 
    builder   => '_build_potcar', 
    handles   => { 
        get_potcars => 'elements' 
    }  
); 

sub BUILD ( $self, @ ) { 
    # check if potential directory is accessible 
    if ( not -d $self->pot_dir ) { 
        die "Please export location of POTCAR files in .bashrc\n
        For example: export POT_DIR=/opt/VASP/POTCAR\n";
    }
} 

sub info ( $self ) { 
    printf  "\n=> Pseudopotential: %s\n", $self->exchange;  
    printf "%-10s %-6s %-10s %-s\n", $_->@[1..4] for $self->get_pp_info; 
} 

sub make ( $self ) { 
    for my $potcar ( $self->get_potcars ) {  
        $self->print( IO::KISS->new( $potcar, 'r' )->slurp ) 
    }
    $self->close_writer; 
} 

# IO:Reader
sub _build_reader ( $self ) { 
    return IO::KISS->new( $self->file, 'r' )
} 

# IO:Writer
sub _build_writer ( $self ) { 
    return IO::KISS->new( $self->file, 'w' )
} 

# IO::Cache
sub _build_cache ( $self ) { 
    my %info = ();  
    my ( $exchange, $element, $pseudo, $config, $date ); 

    # remove \n 
    $self->chomp_reader; 

    for ( $self->get_lines ) { 
        # Ex: VRHFIN =C: s2p2
        if ( /VRHFIN =(\w+)\s*:(.*)/ ) { 
            $element = $1; 
            my @valences = ();  
            
            $config  = ( 
                ( @valences = ($2 =~ /([spdf]\d+)/g) ) ?  
                join '', @valences : 
                (split ' ', $2)[0] 
            )
        }

        # Ex: TITEL  = PAW_PBE C_s 06Sep2000
        if ( /TITEL/ ) { 
            ( $exchange, $pseudo, $date ) = ( split )[2,3,4]; 
            push $info{$exchange}->@*, 
                [ $element, to_Element_Name( $element ), $pseudo, $config, $date //= '---' ]; 
        }
    }
    
    return \%info;  
} 

# native
sub _build_config ( $self ) { 
    my @configs = (); 

    for my $element ( $self->get_elements ) { 
        push @configs, [ 
            map basename($_), 
            grep /\/($element)(\z|\d|_|\.)/, 
            glob "${\$self->pot_dir}/${\$self->exchange}/*" 
        ]; 
    } 

    return \@configs
} 

sub _build_potcar ( $self ) { 
    my @potcars = (); 

    for \ my @configs ( $self->get_configs ) { 
        while ( 1 ) { 
            printf "=> Pseudopotentials < %s >: ", join(' | ', @configs );  
            chomp ( my $choice = <STDIN> =~ s/\s+//rg ); 
            if ( grep $choice eq $_ , @configs ) {  
                push @potcars, catfile( $self->pot_dir, $self->exchange, $choice, 'POTCAR' );  
                last; 
            }
        }
    } 

    return \@potcars 
} 

__PACKAGE__->meta->make_immutable;

1
