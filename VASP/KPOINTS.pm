package VASP::KPOINTS; 

# pragma
use autodie; 
use warnings FATAL => 'all'; 

# core 
use List::Util qw(product); 

# cpan
use Moose;  
use namespace::autoclean; 

# features
use experimental qw(signatures); 

# Moose roles 
with 'IO::Read'; 

# Moose attributes 
has '_read_kpoints', ( 
    is       => 'ro', 
    traits   => ['Hash'], 
    lazy     => 1, 
    init_arg => undef, 

    default  => sub ( $self ) { 
        my $kpoint = {}; 
        my @lines = $self->read_file('KPOINTS')->@*; 
       
        # first three lines are trivial
        $kpoint->@{qw(comment nkpt mode)} = splice @lines, 0, 3; 

        if ( $kpoint->{nkpt} == 0 ) { 
            # automatic k-mesh generation ? 
            $kpoint->{mesh}   = [ map split, shift @lines ];  
            # k-mesh shift 
            $kpoint->{shift}  = [ map split, shift @lines ];  
        } else { 
            # manual k-mesh with weight ? 
            $kpoint->{mesh} = [ map [ (split)[0,1,2] ],  @lines ];  
        }

        return $kpoint; 
    },  

    # delegation 
    handles  => { 'mesh' => [ get => 'mesh' ] }, 
); 

has 'nkpt', ( 
    is       => 'ro', 
    isa      => 'Int', 
    lazy     => 1, 
    init_arg => undef, 

    default  => sub ( $self )  { 
        return product($self->mesh->@*); 
    } 
); 

# Moose methods
sub BUILD ( $self, @args ) { 
    $self->_read_kpoints; 
} 

# speed-up object construction 
__PACKAGE__->meta->make_immutable;

1; 
