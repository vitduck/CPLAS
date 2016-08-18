package VASP::Force; 

# pragma
use autodie; 
use warnings FATAL => 'all'; 

# cpan 
use PDL qw//; 
use Moose::Role; 
use namespace::autoclean; 

# features
use experimental qw/signatures/; 

# Moose class 
use IO::KISS; 

has 'forces', ( 
    is       => 'ro', 
    lazy     => 1, 
    init_arg => undef, 

    default  => sub ( $self ) {
        my $force = [];  

        # match the force block 
        # TODO: is it possible to capture the final three columns 
        #       without explicit spliting later ? 
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

        # regex in list context 
        # loop through each force block
        for my $fblock ( $self->slurp =~ /$regex/g ) { 
            chomp $fblock; 

            # open fh to string 
            my $string = IO::KISS->new($fblock); 

            my $iforce = []; 
            for ( $string->get_lines ) { 
                push $iforce->@*, [(split)[3,4,5]]; 
            } 
            push $force->@*, $iforce; 
        } 

        return $force; 
    }, 
); 

has 'max_forces', ( 
    is       => 'ro', 
    isa      => 'ArrayRef[Str]', 
    lazy     => 1, 
    init_arg => undef, 

    default  => sub ( $self ) { 
        my $pforce = PDL->new($self->forces); 
        my $max_force = ($pforce*$pforce)->sumover
                                         ->sqrt
                                         ->maximum; 

        return [ $max_force->list ]; 
    }, 
); 

1; 
