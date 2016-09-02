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
use VASP::Exchange qw /VASP/;  

# Moose roles 
with qw/IO::Proxy Geometry::Basic/;  

# IO::Proxy
has '+file', ( 
    default   => 'POTCAR', 
); 

has '+parser', ( 
    default   => sub ( $self ) { 
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
                push $info->{$exchange}->@*, [ $element, $potcar, $config, $date ]; 
            }
        }
        # transformation 
        return $info; 
    }, 
);  

# Geometry::Basic
has '+element', ( 
    predicate => 'has_element', 
    default   => sub ( $self ) { 
        my $exchange = $self->exchange; 
        return [ map $_->[0], $self->parser->{$exchange}->@* ]
    } 
); 

# Native
has 'pot_dir', ( 
    is        => 'ro', 
    isa       => Str, 
    init_arg  => undef, 
    default   => $ENV{POT_DIR}, 
); 

has 'exchange', ( 
    is        => 'ro', 
    isa       => VASP, 
    predicate => 'has_exchange', 
    lazy      => 1, 
    default   => sub ( $self ) { 
        my @exchanges = keys $self->parser->%*;  
        # sanity check
        if ( @exchanges > 1 ) { 
            die "More than one kind of PP. Something is wrong ...\n"
        } 
        return shift @exchanges  
    } 
); 

has 'config', ( 
    is        => 'ro', 
    isa       => ArrayRef, 
    traits    => ['Array'], 
    init_arg  => undef, 
    lazy      => 1, 
    default   => sub ( $self ) { 
        return [] 
    },  
    handles   => { 
        add_config  => 'push', 
        get_configs => 'elements',  
    }, 
); 

has 'potcar', ( 
    is        => 'ro', 
    isa       => ArrayRef, 
    traits    => ['Array'], 
    init_arg  => undef, 
    lazy      => 1, 
    default   => sub ( $self ) { 
        return [] 
    },  
    handles   => { 
        add_potcar  => 'push', 
        get_potcars => 'elements',  
    }, 
); 

# Moose method 
sub config_potcar( $self, $element ) { 
    my $config = [ 
        map basename($_), 
        grep /\/($element)(\z|\d|_|\.)/, 
        glob "${\$self->pot_dir}/${\$self->exchange}/*" 
    ];  

    $self->add_config($config); 
} 

sub select_potcar( $self ) { 
    for my $config ( $self->get_configs ) { 
        # construct full path to file
        while ( 1 ) { 
            printf "=> Pseudopotentials < %s >: ", join(' | ', $config->@* );  
            chomp ( my $choice = <STDIN> =~ s/\s+//rg ); 
            if ( grep $choice eq $_ , $config->@* ) {  
                $self->add_potcar( catfile( $self->pot_dir, $self->exchange, $choice, 'POTCAR' ) );  
                last; 
            }
        } 
    }
} 

# Moose method 
sub make_potcar ( $self ) { 
    $self->print( IO::KISS->new( $_, 'r' )->slurp ) for $self->get_potcars;  
} 

sub info ( $self ) { 
    my $exchange = $self->exchange; 
    my @pseudoes = $self->parser->{$exchange}->@*; 
    printf  "\nPseudopotential: %s\n", $exchange; 
    printf "%-6s %-6s %-s\n", $_->@[1..3] for @pseudoes;  
} 

sub BUILD ( $self, @args ) { 
    # check if potential directory is accessible 
    if ( not -d $self->pot_dir  ) { 
        die "Please export location of POTCAR files in .bashrc\n
        For example: export POT_DIR=/opt/VASP/POTCAR\n";
    }
    
    # if a arrayref element is passed to the constructor,  
    if ( $self->has_element && $self->has_exchange ) { 
        $self->config_potcar($_) for $self->get_elements; 
        $self->select_potcar; 
    # cache POTCAR 
    } else { 
        try { $self->parser };  
    } 
} 

# speed-up object construction 
__PACKAGE__->meta->make_immutable;

1; 
