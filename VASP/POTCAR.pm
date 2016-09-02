package VASP::POTCAR; 

# core 
use File::Basename; 
use File::Spec::Functions; 

# cpan
use Data::Printer; 
use Moose;  
use MooseX::Types::Moose qw/Str ArrayRef HashRef/; 
use Try::Tiny; 
use namespace::autoclean; 

# pragma
use autodie; 
use warnings FATAL => 'all'; 
use experimental qw/signatures postderef_qq/;  

# Moose class 
use IO::KISS;  

# Moose type 
use VASP::Exchange qw/VASP/;  
use Periodic::Table qw/Element_Name/; 

# Moose roles 
with qw/IO::Proxy Geometry::Template/;  

# IO::Proxy
has '+file', ( 
    default   => 'POTCAR', 
); 

has '+parser', ( 
    lazy     => 1, 
    builder  => '_parse_POTCAR', 
);  

# Geometry::Template
has '+element', ( 
    lazy      => 1, 
    predicate => 'has_element', 
    builder   => '_build_element', 
); 

# Native
has 'exchange', ( 
    is        => 'ro', 
    isa       => VASP, 
    lazy      => 1, 
    predicate => 'has_exchange', 
    builder   => '_build_exchange',  
); 

has 'pot_dir', ( 
    is        => 'ro', 
    isa       => Str, 
    init_arg  => undef, 
    default   => $ENV{POT_DIR}, 
); 

has 'config', ( 
    is        => 'ro', 
    isa       => ArrayRef, 
    traits    => ['Array'], 
    init_arg  => undef, 
    lazy      => 1, 
    builder   => '_build_config', 
    handles   => { 
        get_configs => 'elements',  
    }, 
); 

has 'potcar', ( 
    is        => 'ro', 
    isa       => ArrayRef, 
    traits    => ['Array'], 
    init_arg  => undef, 
    lazy      => 1, 
    builder   => '_build_potcar',  
    handles   => { 
        get_potcars => 'elements',  
    }, 
); 

#----------------#
#  Public Method #
#----------------#
sub make ( $self ) { 
    $self->print( IO::KISS->new( $_, 'r' )->slurp ) for $self->get_potcars;  
} 

sub info ( $self ) { 
    my $exchange = $self->exchange; 
    my @pseudoes = $self->parser->{$exchange}->@*; 
    printf  "\n=> Pseudopotential: %s\n", $exchange; 
    printf "%-10s %-6s %-6s %-s\n", $_->@* for @pseudoes;  
} 

sub BUILD ( $self, @args ) { 
    # check if potential directory is accessible 
    if ( not -d $self->pot_dir ) { 
        die "Please export location of POTCAR files in .bashrc\n
        For example: export POT_DIR=/opt/VASP/POTCAR\n";
    }
} 

#----------------#
# Private method #
#----------------#
sub _parse_POTCAR ( $self ) { 
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

sub _build_exchange ( $self ) { 
    my @exchanges = keys $self->parser->%*;  
    
    # sanity check
    return ( 
        @exchanges > 1 ? 
        die "More than one kind of PP. Something is wrong ...\n" :  
        shift @exchanges  
    )
} 

sub _build_element ( $self ) { 
    my $exchange = $self->exchange; 
    my @pptable  = $self->parser->{$exchange}->@*;  

    return [ map $_->[0], @pptable ]
} 

sub _build_config( $self ) { 
    my @configs = (); 
    
    for my $element ( $self->get_elements ) { 
        push @configs, [ 
            map basename($_), 
            grep /\/($element)(\z|\d|_|\.)/, 
            glob "${\$self->pot_dir}/${\$self->exchange}/*" 
        ]; 
    } 

    return \@configs; 
} 

sub _build_potcar( $self ) { 
    my @potcars = (); 

    # construct full path to file
    for my $config ( $self->get_configs ) { 
        while ( 1 ) { 
            printf "=> Pseudopotentials < %s >: ", join(' | ', $config->@* );  
            chomp ( my $choice = <STDIN> =~ s/\s+//rg ); 
            if ( grep $choice eq $_ , $config->@* ) {  
                push @potcars, catfile( $self->pot_dir, $self->exchange, $choice, 'POTCAR' );   
                last; 
            }
        }
    } 

    return \@potcars; 
} 

# speed-up object construction 
__PACKAGE__->meta->make_immutable;

1; 
