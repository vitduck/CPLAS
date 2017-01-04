package VASP::Force; 

use Moose; 
use MooseX::Types::Moose qw/Int RegexpRef/; 
use VASP::POSCAR; 

use namespace::autoclean; 
use experimental 'signatures'; 

with 'VASP::OUTCAR::IO'; 
with 'VASP::OUTCAR::Force'; 
with 'MooseX::Getopt::Usage'; 

has '+input', ( 
    default   => 'OUTCAR', 

    documentation => 'Input file'
); 

has 'column', ( 
    is        => 'ro', 
    isa       => Int, 
    lazy      => 1, 
    default   => 4, 

    documentation => 'Number of formatted column'
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
        printf "%${digit}d f = %.2e    ", $indices[$i]+1, $forces[ $indices[$i] ]; 
    
        # the last of us 
        last if $i == $#indices;  

        # break new line due to index wrap around
        print "\n" if $indices[ $i ] > $indices[ $i+1 ] or $self->column == 1; 
    }

    # trailing \n 
    print "\n"; 
} 

__PACKAGE__->meta->make_immutable;

1
