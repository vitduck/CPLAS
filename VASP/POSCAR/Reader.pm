package VASP::POSCAR::Reader; 

use Moose::Role; 
use IO::KISS; 
use VASP::POTCAR; 
use Periodic::Table qw( Element ); 
use namespace::autoclean; 
use experimental qw( signatures );  

sub _build_cache ( $self ) { 
    my %poscar = ();  

    # header
    $poscar{ comment } = $self->_get_line; 
    $poscar{ scaling } = $self->_get_line; 
    $poscar{ lattice }->@* = map [ split ' ', $self->_get_line  ], 0..2; 

    # natom and element 
    my ( @natoms, @elements ); 
    my @has_VASP5 = split ' ', $self->_get_line; 
    if ( ! grep Element->check( $_ ), @has_VASP5 ) { 
        $poscar{ version } = 4; 

        # show POTCAR info 
        my $potcar = VASP::POTCAR->new; 
        $potcar->info; 

        # get elements from POTCAR
        @elements = $potcar->get_elements;  
        @natoms   = @has_VASP5;  
        @elements = splice @elements, 0, scalar( @natoms ); 
    } else { 
        $poscar{ version } = 5; 

        @elements = @has_VASP5; 
        @natoms   = split ' ', $self->_get_line; 
    } 

    # build list of atom
    my @atoms = map { ( $elements[$_] ) x $natoms[$_] } 0..$#elements; 
   
    # selective dynamics 
    my $has_selective = $self->_get_line; 
    if ( $has_selective =~ /^\s*S/i ) { 
        $poscar{ selective } = 1; 
        $poscar{ type }      = $self->_get_line; 
    } else { 
        $poscar{ selective } = 0; 
        $poscar{ type }      = $has_selective; 
    } 

    # coodinate and dynamics
    my ( @coordinates, @dynamics );  
    while ( defined( local $_ = $self->_get_line ) ) { 
        # blank line separate geometry and velocity blocks
        last if /^\s+$/; 
        
        # 1st 3 columns are coordinate 
        # if remaining column is either 0 or 1 (w/o indexing) 
        # the POSCAR contains no selective dynamics block 
        my @columns = split; 
        push @coordinates, [ splice @columns, 0, 3 ];  
        push @dynamics, ( 
            @columns == 0 || @columns == 1
            ? [ qw( T T T ) ] 
            : [ splice @columns, 0, 3 ]
        ); 
    } 
    
    # indexing 
    $poscar{ atom }       = { map { $_+1 => $atoms[ $_ ] } 0..$#atoms };   
    $poscar{ dynamics }   = { map { $_+1 => $dynamics[ $_ ] } 0..$#dynamics };  
    $poscar{ coordinate } = { map { $_+1 => $coordinates[ $_ ] } 0..$#coordinates };  
    
    $self->_close_reader; 

    return \%poscar; 
}

1
