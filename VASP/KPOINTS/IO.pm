package VASP::KPOINTS::IO;  

use Moose::Role;  

use namespace::autoclean; 
use feature 'switch';  
use experimental qw/signatures smartmatch/;    

with 'IO::Reader'; 
with 'IO::Cache';  

sub _build_cache ( $self ) { 
    my %cache = ();  

    $cache{ comment } = $self->get_line;   
    $cache{ imode   } = $self->get_line;   
    $cache{ scheme  } = (
        $self->get_line =~ /^M/ 
        ? 'Monkhorst-Pack' 
        : 'Gamma-centered' 
    );

    # kmode  
    given ( $cache{ imode } ) {   
        # automatic k-messh
        when ( 0 ) { 
            $cache{ mode } = 'automatic'; 
            $cache{ grid } = [ 
                map int, 
                map split, 
                $self->get_line 
            ] 
        }

        # manual k-mesh 
        when ( $_ > 0 ) { 
            $cache{ mode } = 'manual'; 
            $cache{ grid } = [ 
                map [ ( split )[0..2] ],  
                $self->get_lines 
            ]
        } 

        # line mode ( band calculation ) 
        # TBI 
        default { 
            $cache{ mode } = 'line'
        }
    }
    
    # mesh shift
    $cache{ shift } = (
        $cache{ imode } == 0 
        ? [ split ' ', $self->get_line ]
        : [ 0, 0, 0 ]
    ); 
    
    return \%cache; 
} 

1 
