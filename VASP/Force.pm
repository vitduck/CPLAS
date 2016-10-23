package VASP::Force; 

use Moose; 
use MooseX::Types::Moose qw( Int RegexpRef ); 
use IO::KISS;
use VASP::POSCAR; 
use Try::Tiny; 
use PDL::Lite; 
use namespace::autoclean; 
use experimental qw( signatures );  

with qw( MooseX::Getopt::Usage ); 
with qw( IO::Reader ); 

# Getopt
has '+input', ( 
    default   => 'OUTCAR', 

    documentation => 'Input file'
); 

has 'column', ( 
    is        => 'ro', 
    isa       => Int, 
    lazy      => 1, 
    default   => '5', 

    documentation => 'Number of formatted column'
); 

# native
has '_force_regex', ( 
    is        => 'ro', 
    isa       => RegexpRef, 
    lazy      => 1, 
    init_arg  => undef, 
    builder   => '_build_force_regex'
); 

has '_force', ( 
    is       => 'ro', 
    isa      => 'PDL', 
    init_arg => undef, 
    lazy     => 1, 
    builder  => '_build_force' 
); 

has '_max_force', ( 
    is        => 'ro', 
    isa       => 'PDL', 
    init_arg  => undef, 
    lazy      => 1, 
    builder   => '_build_max_force', 
    handles   => { 
        get_max_forces => 'list' 
    } 
); 

has '_POSCAR', ( 
    is        => 'ro', 
    isa       => 'VASP::POSCAR',   
    lazy      => 1, 
    init_arg  => undef, 
    default   => sub { VASP::POSCAR->new },  
    handles   => { 
        _true_indices  => 'get_true_indices', 
        _false_indices => 'get_false_indices'
    }
); 

sub print_forces ( $self ) { 
    my @forces = $self->get_max_forces; 

    # table format
    my $nrow = 
        @forces % $self->column 
        ? int( @forces / $self->column ) + 1 
        : @forces / $self->column; 

    # sort force indices based on modulus 
    my @indices = sort { $a % $nrow <=> $b % $nrow } 0..$#forces; 

    # for formating 
    my $digit = length( scalar( @forces ) ); 

    for my $i ( 0..$#indices ) { 
        printf "%${digit}d: f = %.2e    ", $indices[$i]+1, $forces[ $indices[$i] ]; 
    
        # the last of us 
        last if $i == $#indices;  

        # break new line due to index wrap around
        print "\n" if $indices[ $i ] > $indices[ $i+1 ] or $self->column == 1; 
    }

    # trailing \n 
    print "\n"; 
} 

# match the force block 
# TODO: is it possible to capture the final three columns 
#       without explicit split
sub _build_force_regex ( $self ) { 
    return 
        qr/
            (?:
                \ POSITION\s+TOTAL-FORCE\ \(eV\/Angst\)\n
                \ -+\n
            )
            (.+?) 
            (?: 
                \ -+\n
            )
        /xs 
} 

# perform regex in list context 
# open FH to force block string and iterate over each line 
# The 3,4, and 5 column are fx, fy, and fz 
# @forces is a 3d matrix with dimension of NSW x NIONS x 3
sub _build_force ( $self ) { 
    my ( @forces, @true_indices, @false_indices ); 

    try { 
        @true_indices  = $self->_true_indices; 
        @false_indices = $self->_false_indices  
    } 
    
    catch { 
        @false_indices = ()  
    }; 

    for ( $self->_slurp =~ /${ \$self->_force_regex }/g ) { 
        my @iforces;  

        for ( IO::KISS->new( \$_, 'r' )->get_lines ) { 
            push @iforces, [ ( split )[ 3..5 ] ]
        }

        push @forces, \@iforces; 
    }

    return 
        @false_indices == 0 
        ? PDL->new( \@forces ) 
        : PDL->new( \@forces )->dice( 'X', \@true_indices, 'X' ) 
} 

# Dimensions of PDL piddle is reversed w.r.t standard matrix notation 
# Dimension of the force 3d matrix is: 3 x NIONS x NSW ( instead of NSW x NIONS x 3 )
# However, this facilitate dimensional reduction operator as following: 
sub _build_max_force ( $self ) { 
    return ( $self->_force * $self->_force )->sumover->sqrt->maximum; 
} 

1
