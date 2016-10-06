package VASP::POTCAR::Reader;  

use Moose::Role; 
use Periodic::Table qw( Element_Name );
use namespace::autoclean; 
use experimental qw( signatures ); 

sub _build_cache ( $self ) { 
    my %info; 
    my ( $exchange, $element, $pseudo, $valence, $date ); 
    my @split_valences; 

    for ( $self->_get_lines ) { 
        chomp; 
        # Ex: VRHFIN =C: s2p2
        if ( /VRHFIN =(\w+)\s*:(.*)/ ) { 
            $element = $1; 
            @split_valences = ( $2 =~ /([spdf]\d+)/g ); 

            $valence  =  
                @split_valences  
                ? join '', @split_valences 
                : ( split ' ', $2 )[ 0 ]; 
        }

        # Ex: TITEL  = PAW_PBE C_s 06Sep2000
        if ( /TITEL/ ) { 
            ( $exchange, $pseudo, $date ) = ( split )[ 2..4 ]; 

            push $info{ $exchange }->@*, 
                [ to_Element_Name( $element ), $pseudo, $valence, $date //= '---' ]; 
        }
    }

    $self->_close_reader; 

    return \%info;  
} 

1
