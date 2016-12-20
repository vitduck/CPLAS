package VASP::Pseudo::IO;  

use Moose::Role;  
use IO::KISS; 
use File::Spec::Functions; 
use Periodic::Table qw/Element Element_Name/; 

use namespace::autoclean; 
use experimental 'signatures';  

with 'IO::Reader';  
with 'IO::Cache'; 

sub _build_input ( $self ) { 
    return catfile( 
        $self->get_potcar_dir,
        $self->get_xc, 
        $self->get_config,  
        'POTCAR' 
    ), 
} 

sub _build_cache ( $self ) { 
    my %cache; 

    # fh to slurped POTCAR
    my $io = IO::KISS->new( \ $self->get_potcar, 'r' );  
    
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

1
