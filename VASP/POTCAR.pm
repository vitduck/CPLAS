package VASP::POTCAR; 

# core 
use File::Basename; 
use File::Spec::Functions; 

# cpan
use Data::Printer; 
use Moose;  
use MooseX::Types::Moose qw/Str ArrayRef HashRef/; 
use namespace::autoclean; 

# pragma
use autodie; 
use warnings FATAL => 'all'; 
use experimental qw/signatures postderef_qq/; 

# Moose class 
use IO::KISS;  

# Moose type 
use VASP::Exchange qw/VASP/; 

# Moose roles 
with qw/VASP::IO VASP::Geometry/; 

# Moose attributes 
has 'pot_dir', ( 
    is        => 'ro', 
    isa       => Str, 
    init_arg  => undef, 
    default   => $ENV{POT_DIR}, 
); 

# VASP::IO
has '+file', ( 
    default   => 'POTCAR', 
); 

has '+parse', ( 
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

# VASP::Geometry
has '+element', ( 
    predicate => 'has_element', 
    default   => sub ( $self ) { 
        return [ map $_->[0], $self->extract($self->exchange)->@* ]
    } 
); 

has 'exchange', ( 
    is        => 'rw', 
    isa       => VASP, 
    predicate => 'has_exchange', 
    lazy      => 1, 
    default   => sub ( $self ) { 
        return ($self->keywords)[0]   
    } 
); 

for my $name ( qw/config potcar/ ) { 
    has $name, ( 
        is        => 'ro', 
        isa       => ArrayRef, 
        traits    => ['Array'], 
        init_arg  => undef, 
        lazy      => 1, 
        default   => sub ( $self ) { return [] },  
        handles   => { 
            'add_'.$name     => 'push', 
            'get_'.$name     => 'shift',  
            'get_'.$name.'s' => 'elements',  
        }
    ); 
}

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
        # prompt 
        # $config itselft is a ArrayRef
        printf "=> Pseudopotentials < %s >: ", join(' | ', $config->@* );  

        # construct full path to file
        while ( 1 ) { 
            chomp ( my $choice = <STDIN> =~ s/\s+//rg ); 
            if ( grep $choice eq $_ , $config->@* ) {  
                $self->add_potcar(catfile($self->pot_dir, $self->exchange, $choice, 'POTCAR'));  
                last; 
            }
        } 
    }
} 

# Moose method 
sub make_potcar ( $self ) { 
    my $POTCAR = IO::KISS->new('POTCAR', 'w');      

    for my $potcar ( $self->get_potcars ) { 
        $POTCAR->print( IO::KISS->new($potcar, 'r')->slurp ); 
    }
} 

sub info ( $self ) { 
    printf  "\nPseudopotential: %s\n", $self->exchange; 
    for my $pseudo ( $self->extract($self->exchange) ) {  
        for my $element ( $pseudo->@* ) { 
            printf "%-6s %-6s %-s\n", $element->@[1..3]; 
        } 
    } 
} 

sub BUILD ( $self, @args ) { 
    # check if potential directory is accessible 
    if ( not -d $self->pot_dir  ) { 
        die "Please export location of POTCAR files in .bashrc\n
        For example: export POT_DIR=/opt/VASP/POTCAR\n";
    }
    
    # if a arrayref element is passed to the constructor,  
    if ( $self->has_element && $self->has_exchange ) { 
        for my $element ( $self->get_elements ) { 
            $self->config_potcar($element); 
        } 
        $self->select_potcar; 
    }
} 

# speed-up object construction 
__PACKAGE__->meta->make_immutable;

1; 
