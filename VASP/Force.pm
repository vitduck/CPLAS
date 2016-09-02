package VASP::Force; 

# cpan 
use PDL::Lite; 
use Moose::Role; 
use MooseX::Types::Moose qw//; 
use namespace::autoclean; 

# pragma
use warnings FATAL => 'all'; 
use experimental qw/signatures/;  

# Moose class 
use VASP::POSCAR;  
use IO::KISS; 

# match the force block 
# TODO: is it possible to capture the final three columns 
#       without explicit spliting later ? 
has 'force', ( 
    is       => 'ro', 
    isa      => 'PDL', 
    init_arg => undef, 
    lazy     => 1, 
    builder  => '_parse_force_block',  
); 

has 'max_force', ( 
    is        => 'ro', 
    isa       => 'PDL', 
    init_arg  => undef, 
    lazy      => 1, 
    default   => sub ( $self ) { 
        return ( $self->force * $self->force )->sumover->sqrt->maximum; 
    }, 
    handles   => { 
        get_max_forces => 'list' 
    }, 
); 

#----------------#
# Private Method #
#----------------#
sub _parse_force_block ( $self ) { 
    # compiled regex for force block
    my $regex = 
    qr/
        (?:
            \ POSITION\s+TOTAL-FORCE\ \(eV\/Angst\)\n
            \ -+\n
        )
        (.+?) 
        (?: 
            \ -+\n
        )
    /xs; 

    # slurp OUTCAR and perform regex in list context 
    my $force =  PDL->new( 
        map [ map [ (split)[3,4,5] ], IO::KISS->new(\$_, 'r')->get_lines ], ( $self->slurp =~ /$regex/g )
    ); 

    # constraint from POSCAR
    return $force->dice('X',[ VASP::POSCAR->new()->get_true_indices ], 'X'); 
} 

1; 
