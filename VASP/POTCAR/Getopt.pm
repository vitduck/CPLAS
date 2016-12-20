package VASP::POTCAR::Getopt;  

use Moose;  

use namespace::autoclean; 
use experimental 'signatures';  

with 'MooseX::Getopt::Usage';  

has '+extra_argv', ( 
    traits   => [ 'Array' ], 
    handles  => { 
        get_arg  => 'shift', 
        get_args => 'elements'   
    }
); 

sub help ( $self ) { 
    print $self->getopt_usage
} 

sub getopt_usage_config ( $self ) {
    return ( 
        format   => "Usage: %c <info|make|add|remove|order|select> [OPTIONS]", 
        headings => 1
    )
}

__PACKAGE__->meta->make_immutable;

1
