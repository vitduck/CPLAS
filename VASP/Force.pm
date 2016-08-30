package VASP::Force; 

# cpan 
use PDL::Lite; 
use Moose::Role; 
use MooseX::Types::Moose qw/ArrayRef Str/; 
use namespace::autoclean; 

# pragma
use autodie; 
use warnings FATAL => 'all'; 
use experimental qw/signatures/; 

# Moose class 
use IO::KISS; 

# match the force block 
# TODO: is it possible to capture the final three columns 
#       without explicit spliting later ? 
has 'force', ( 
    is       => 'ro', 
    isa      => ArrayRef, 
    init_arg => undef, 
    lazy     => 1, 
    default  => sub ( $self ) { 
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
        my $force = []; 
        for my $fblock ( $self->slurp =~ /$regex/g ) { 
            push $force->@*, [ map [ (split)[3,4,5] ], IO::KISS->new($fblock, 'r')->get_lines ];   
        } 
        return $force;  
    }, 
); 

has 'max_force', ( 
    is        => 'ro', 
    isa       => ArrayRef[Str], 
    traits    => ['Array'], 
    init_arg  => undef, 
    lazy      => 1, 
    default   => sub ( $self ) { 
        my $force = PDL->new($self->force); 
        return [ ($force*$force)->sumover->sqrt->maximum->list ] 
    }, 
    handles   => {  
        get_max_force  => 'shift', 
        get_max_forces => 'elements', 
    }, 
); 

1; 
