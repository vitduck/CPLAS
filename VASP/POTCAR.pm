package VASP::POTCAR; 

use strict; 
use warnings FATAL => 'all'; 
use feature 'signatures','refaliasing'; 
use namespace::autoclean; 

use File::Basename; 
use File::Spec::Functions; 
use Moose;  
use MooseX::Types::Moose 'Str','ArrayRef','HashRef'; 
use IO::KISS;  
use Types::Exchange 'VASP_PP';  
use Types::Periodic 'Element','Element_Name';  

no warnings 'experimental'; 

with 'IO::Reader','IO::Writer';  

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
    builder   => '_build_element', 
    handles   => { get_elements => 'elements' } 
); 

has 'exchange', ( 
    is        => 'ro', 
    isa       => VASP_PP, 
    lazy      => 1, 
    builder   => '_build_exchange' 
); 

has 'pp_info', (  
    is        => 'ro', 
    isa       => ArrayRef, 
    traits    => [ 'Array' ], 
    lazy      => 1, 
    builder   => '_build_pp_info', 
    handles   => { get_pp_info => 'elements' } 
); 

has 'config', ( 
    is        => 'ro', 
    isa       => ArrayRef, 
    traits    => [ 'Array' ], 
    lazy      => 1, 
    init_arg  => undef, 
    builder   => '_build_config', 
    handles   => { get_configs => 'elements' } 
); 

has 'potcar', ( 
    is        => 'ro', 
    isa       => ArrayRef[Str], 
    traits    => [ 'Array' ], 
    lazy      => 1, 
    init_arg  => undef, 
    builder   => '_build_potcar', 
    handles   => { get_potcars => 'elements' }  
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
    $self->close; 
} 

sub _build_element ( $self ) { 
    return [ map $_->[0], $self->get_pp_info ] 
}

sub _build_pp_info ( $self ) { 
    return $self->read( $self->exchange )      
}

sub _build_exchange ( $self ) { 
    my @exchanges = keys $self->reader->%*;  

    return ( 
        @exchanges > 1 ? 
        die "More than one kind of PP. Something is wrong ...\n" :  
        shift @exchanges  
    )
}  

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

sub _parse_file ( $self ) { 
    my %info = ();  
    my ( $exchange, $element, $pseudo, $config, $date ); 
    
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
            $date //= '---'; 
            push $info{$exchange}->@*, 
                [ $element, to_Element_Name($element), $pseudo, $config, $date ]; 
        }
    }

    return \%info;  
} 

__PACKAGE__->meta->make_immutable;

1; 
