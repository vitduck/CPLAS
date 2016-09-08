package VASP::POTCAR; 

use Moose;  
use MooseX::Types::Moose qw( Str ArrayRef HashRef ); 
use Types::Exchange qw( VASP_PP );  
use Types::Periodic qw( Element Element_Name ); 

use File::Basename; 
use File::Spec::Functions; 

use strictures 2; 
use namespace::autoclean; 
use experimental qw( signatures postderef_qq );  

use IO::KISS;  
with qw( IO::Parser ); 

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

    default   => sub ( $self ) { 
        return [ map $_->[0], $self->get_pp_info ] 
    },  

    handles   => { 
        get_elements => 'elements' 
    }, 
); 

has 'exchange', ( 
    is        => 'ro', 
    isa       => VASP_PP, 
    lazy      => 1, 

    default   => sub ( $self ) { 
        my @exchanges = $self->list;  
        
        # sanity check
        return ( 
            @exchanges > 1 ? 
            die "More than one kind of PP. Something is wrong ...\n" :  
            shift @exchanges  
        )
    },  
); 

has 'pp_info', (  
    is        => 'ro', 
    isa       => ArrayRef, 
    traits    => [ 'Array' ], 
    lazy      => 1, 

    default   => sub ( $self ) { 
        return $self->read( $self->exchange )  
    },  

    handles   => {  
        get_pp_info => 'elements' 
    }, 
); 

has 'config', ( 
    is        => 'ro', 
    isa       => ArrayRef, 
    traits    => [ 'Array' ], 
    lazy      => 1, 
    init_arg  => undef, 

    default   => sub ( $self ) { 
        my $config = []; 

        for my $element ( $self->get_elements ) { 
            push $config->@*, [ 
                map basename($_), 
                grep /\/($element)(\z|\d|_|\.)/, 
                glob "${\$self->pot_dir}/${\$self->exchange}/*" 
            ]; 
        } 

        return $config
    },  

    handles   => { 
        get_configs => 'elements' 
    }, 
); 

has 'potcar', ( 
    is        => 'ro', 
    isa       => ArrayRef[Str], 
    traits    => [ 'Array' ], 
    lazy      => 1, 
    init_arg  => undef, 

    default   => sub ( $self ) { 
        my $potcar = []; 

        for my $config ( $self->get_configs ) { 
            while ( 1 ) { 
                printf "=> Pseudopotentials < %s >: ", join(' | ', $config->@* );  
                chomp ( my $choice = <STDIN> =~ s/\s+//rg ); 
                if ( grep $choice eq $_ , $config->@* ) {  
                    push $potcar->@*, catfile( $self->pot_dir, $self->exchange, $choice, 'POTCAR' );  
                    last; 
                }
            }
        } 

        return $potcar;  
    },  
   
    handles   => { 
        get_potcars => 'elements' 
    },  
); 

sub _parse_file ( $self ) { 
    my $info = { };  
    my $fh = IO::KISS->new( $self->file, 'r' ); 
    my ( $exchange, $element, $pseudo, $config, $date ); 
    
    for ( $fh->get_lines ) { 
        # Ex: VRHFIN =C: s2p2
        if ( /VRHFIN =(\w+)\s*:(.*)/ ) { 
            $element = $1; 
            my @valences;  
            $config  = 
            ( @valences = ($2 =~ /([spdf]\d+)/g) ) ?  
            join '', @valences : 
            (split ' ', $2)[0]; 
        }
        # Ex: TITEL  = PAW_PBE C_s 06Sep2000
        if ( /TITEL/ ) { 
            ( $exchange, $pseudo, $date ) = ( split )[2,3,4]; 
            $date //= '---'; 
            push $info->{$exchange}->@*, 
                [ $element, to_Element_Name($element), $pseudo, $config, $date ]; 
        }
    }

    $fh->close; 

    return $info; 
} 

sub BUILD ( $self, @args ) { 
    # check if potential directory is accessible 
    if ( not -d $self->pot_dir ) { 
        die "Please export location of POTCAR files in .bashrc\n
        For example: export POT_DIR=/opt/VASP/POTCAR\n";
    }
} 

sub make ( $self ) { 
    my $fh = IO::KISS->new( $self->file, 'w' ); 

    $fh->print( IO::KISS->new( $_, 'r' )->get_string ) for $self->get_potcars;  

    $fh->close; 
} 

sub info ( $self ) { 
    printf  "\n=> Pseudopotential: %s\n", $self->exchange;  
    printf "%-10s %-6s %-10s %-s\n", $_->@[1..4] for $self->get_pp_info; 
} 

# speed-up object construction 
__PACKAGE__->meta->make_immutable;

1; 
