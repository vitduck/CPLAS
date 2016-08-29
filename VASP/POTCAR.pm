package VASP::POTCAR; 

# core 
use File::Basename; 
use File::Spec::Functions; 

# cpan
use Data::Printer; 
use Moose;  
use MooseX::Types::Moose qw/ArrayRef HashRef Str/;  
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
with qw/VASP::Parser VASP::Geometry/; 

# Moose attributes 
has 'pot_dir', ( 
    is        => 'ro', 
    isa       => Str, 
    init_arg  => undef, 
    default   => $ENV{POT_DIR} 
); 

# VASP::Parser
has '+file', ( 
    lazy      => 1, 
    default   => 'POTCAR', 
); 

has '+parser', ( 
    lazy      => 1, 
    default   => sub ( $self ) { 
        my $info = {};  
        my ( $exchange, $element, $potcar, $config, $date ); 
        my @valences;  
        for ( $self->get_lines ) { 
            # Ex: VRHFIN =C: s2p2
            if ( /VRHFIN =(\w+)\s*:(.*)/ ) { 
                $element = $1; 
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
has '+elements', ( 
    predicate => 'has_elements', 
    lazy      => 1, 
    default   => sub ( $self ) { 
        my $pseudo = $self->parse($self->exchange);  
        return [ map $_->[0], $pseudo->@* ]  
    } 
); 

has 'exchange', ( 
    is        => 'rw', 
    isa       => VASP, 
    predicate => 'has_exchange', 
    lazy      => 1, 
    default   => sub ( $self ) { 
        return ($self->keyword)[0]   
    } 
); 


has 'available_potcars', ( 
    is        => 'ro', 
    isa       => HashRef, 
    traits    => ['Hash'], 
    init_arg  => undef, 
    lazy      => 1, 
    default   => sub ( $self ) { {} },  
    handles   => { 
        set_available_potcars  => 'set',  
        list_available_potcars => 'get',  
    }
); 

has 'selected_potcars', ( 
    is        => 'ro', 
    isa       => HashRef, 
    traits    => ['Hash'], 
    init_arg  => undef, 
    lazy      => 1, 
    default   => sub ( $self ) { {} },  
    handles   => { 
        set_selected_potcars => 'set',  
        get_selected_potcars => 'get', 
    }
); 

# Moose private method 
sub _construct_available_potcars( $self, $element ) { 
    $self->set_available_potcars( 
        $element => [ 
            map basename($_), 
            grep /\/($element)(\z|\d|_|\.)/, 
            glob "${\$self->pot_dir}/${\$self->exchange}/*" 
        ]  
    );  
} 

sub _construct_selected_potcars( $self, $element ) { 
    my @potcars = $self->list_available_potcars($element)->@*; 
    
    # prompt 
    printf 
        "\n=> Pseudopotentials for %s: =| %s |=\n", 
        $element, join(' | ', @potcars );  

    # construct full path to file
    while ( 1 ) { 
        print "=> Choice: "; 
        chomp ( my $choice = <STDIN> =~ s/\s+//rg ); 
        if ( grep $choice eq $_ , @potcars ) {  
            $self->set_selected_potcars(
                $element => catfile($self->pot_dir, $self->exchange, $choice, 'POTCAR') 
            );  
            last; 
        }
    } 
} 

# Moose method 
sub make_potcar ( $self ) { 
    my $POTCAR = IO::KISS->new('POTCAR', 'w');      

    for my $element ( $self->list_elements ) { 
        $POTCAR->print(
            IO::KISS->new($self->get_selected_potcars($element), 'r')->slurp 
        )
    }
} 

sub info ( $self ) { 
    my $exchange = $self->exchange; 
    printf  "\nPseudopotential: %s\n", $exchange; 
    for my $pseudo ( $self->parse($exchange) ) {  
        for my $row ( $pseudo->@* ) { 
            printf "%3s => ( %-7s %-10s %-s )\n", $row->@*; 
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
    # set two attributes available_potcars and selected_potcars 
    if ( $self->has_elements && $self->has_exchange ) { 
        for my $element ( $self->list_elements ) { 
            $self->_construct_available_potcars($element); 
            $self->_construct_selected_potcars($element); 
        } 
    }
} 

# speed-up object construction 
__PACKAGE__->meta->make_immutable;

1; 
