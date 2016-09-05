package VASP::POTCAR; 

use Moose;  
use MooseX::Types::Moose qw/Str ArrayRef HashRef/; 
use Data::Printer; 
use File::Basename; 
use File::Spec::Functions; 

use strictures 2; 
use namespace::autoclean; 
use experimental qw/signatures postderef_qq/;  

# Moose class 
use IO::KISS;  
use Periodic::Table qw/Element_Name/; 
use VASP::Exchange qw/VASP/;  
with qw/IO::RW/; 

# IO::RW
has '+file', ( 
    default   => 'POTCAR', 
); 

has 'pot_dir', ( 
    is        => 'ro', 
    isa       => Str, 
    lazy      => 1, 
    init_arg  => undef, 
    default   => $ENV{POT_DIR}, 
); 

has 'element', ( 
    is        => 'ro', 
    isa       => ArrayRef, 
    traits    => ['Array'], 
    lazy      => 1, 

    default   => sub ( $self ) { 
        my $exchange = $self->exchange; 
        my @pptable  = $self->parser->{$exchange}->@*;  
        return [ map $_->[1], @pptable ]
    }, 

    handles   => { 
        get_elements => 'elements'
    }, 
); 

has 'exchange', ( 
    is        => 'ro', 
    isa       => VASP, 
    lazy      => 1, 

    default   => sub ( $self ) { 
        my @exchanges = keys $self->_parse_file->%*;   
        return ( 
            @exchanges > 1 ? 
            die "More than one kind of PP. Something is wrong ...\n" :  
            shift @exchanges  
        )
    },  
); 

has 'config', ( 
    is        => 'ro', 
    isa       => ArrayRef, 
    traits    => ['Array'], 
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
    isa       => ArrayRef, 
    traits    => ['Array'], 
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

sub BUILD ( $self, @args ) { 
    # check if potential directory is accessible 
    if ( not -d $self->pot_dir ) { 
        die "Please export location of POTCAR files in .bashrc\n
        For example: export POT_DIR=/opt/VASP/POTCAR\n";
    }
} 

sub make ( $self ) { 
    $self->print( IO::KISS->new( $_, 'r' )->get_string ) for $self->get_potcars;  
} 

sub info ( $self ) { 
    my $exchange = $self->exchange; 
    my @pseudoes = $self->parser->{$exchange}->@*; 
    printf  "\n=> Pseudopotential: %s\n", $exchange; 
    printf "%-10s %-6s %-6s %-s\n", $_->@* for @pseudoes;  
} 

sub _parse_file ( $self ) { 
    my $info = {};  
    my ( $exchange, $element, $potcar, $config, $date ); 
    for ( $self->get_lines ) { 
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
            ( $exchange, $potcar, $date ) = ( split )[2,3,4]; 
            $date //= '---'; 
            push $info->{$exchange}->@*, [ to_Element_Name($element), $potcar, $config, $date ]; 
        }
    }

    return $info; 
} 

# speed-up object construction 
__PACKAGE__->meta->make_immutable;

1; 
