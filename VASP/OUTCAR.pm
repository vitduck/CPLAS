package VASP::OUTCAR; 

# pragma
use autodie; 
use warnings FATAL => 'all'; 

# cpan
use Moose;  
use namespace::autoclean; 

# features
use experimental qw(signatures); 

# Moose roles 
with 'IO::Read'; 

# Moose attributes 
has '_read_OUTCAR', ( 
    is       => 'ro', 
    isa      => 'Str', 
    init_arg => undef, 

    default  => sub ( $self ) { 
        return $self->slurp('OUTCAR'); 
    }, 
); 

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
            # beginning 
            (?:
                POSITION\s+TOTAL-FORCE\ \(eV\/Angst\)\n
                \ -+\n
            )
            
            # x y z fx fy fz 
            (.+?)
            
            # ending 
            (?: 
                \ -+\n
            )
        /xs; 

        # regex in list context 
        # loop through each force block
        for my $fblock ( $self->_read_OUTCAR =~ /$regex/g ) { 
            my $iforce = []; 

            # open fh to string and loop over deref 
            for ( $self->readline($fblock)->@* ) { 
                push $iforce->@*, [(split)[3,4,5]]; 
            } 
            push $force->@*, $iforce; 
        } 

        return $force; 
    }, 
); 

# Moose methods
sub BUILD ( $self, @args ) { 
    $self->_read_OUTCAR; 
} 

# speed-up object construction 
__PACKAGE__->meta->make_immutable;

1; 
