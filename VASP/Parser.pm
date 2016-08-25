package VASP::Parser; 

# cpan 
use Moose::Role; 
use MooseX::Types;  
use namespace::autoclean; 

# pragma 
use autodie; 
use warnings FATAL => 'all'; 
use experimental qw/signatures/;

use IO::KISS; 

has 'file', ( 
    is        => 'ro', 
    isa       => 'Str', 
    init_arg  => undef, 
); 

# default is line by line process 
# excepts for very large file 
has 'parse_mode', ( 
    is        => 'ro', 
    isa       => enum([ qw/slurp line paragraph/ ]), 
    init_arg  => undef, 

    default   => 'line', 
); 

has 'content', ( 
    is        => 'ro', 
    lazy      => 1, 
    init_arg  => undef, 

    default   => sub ( $self ) { 
        my $io   = IO::KISS->new($self->file, 'r'); 
        my $mode = $self->parse_mode;  

        return $io->$mode; 
    } 
);  

1; 
