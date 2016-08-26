package VASP::Force; 

# cpan 
use PDL::Lite; 
use Moose::Role; 
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
has 'read_forces', ( 
    is       => 'ro', 
    lazy     => 1, 
    init_arg => undef, 

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
        my @forces; 
        for my $fblock ( $self->slurp =~ /$regex/g ) { 
            chomp $fblock; 
            my $string = IO::KISS->new($fblock, 'r'); 
            push @forces, [ map [ (split)[3,4,5] ], $string->get_lines ];   
        } 
        return \@forces; 
    }, 
); 

has 'max_forces', ( 
    is       => 'ro', 
    isa      => 'ArrayRef[Str]', 
    lazy     => 1, 
    init_arg => undef, 
    default  => sub ( $self ) { 
        my $force = PDL->new($self->read_forces); 
        return [ ($force*$force)->sumover->sqrt->maximum->list ] 
    }, 
); 

1; 
