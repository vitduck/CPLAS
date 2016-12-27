package VASP::POTCAR; 

use Moose;  
use MooseX::Types::Moose qw/Str ArrayRef/;  
use VASP::Types 'Pseudo'; 

use namespace::autoclean; 
use experimental 'signatures';  

extends 'VASP::POTCAR::Getopt'; 

with 'VASP::POTCAR::IO';  
with 'VASP::POTCAR::Pseudo';  

has '+input', ( 
    init_arg  => undef, 
    default   => 'POTCAR'
); 

has '+output', ( 
    init_arg  => undef, 
    default   => 'POTCAR'
); 

has '+o_mode', ( 
    default   => 'a'
); 

has 'xc', ( 
    is        => 'ro', 
    isa       => Pseudo, 
    lazy      => 1, 
    reader    => 'get_xc', 
    default   => 'PAW_PBE', 

    documentation => 'XC potential'
); 

sub make ( $self ) {  
    $self->delete; 
    $self->add; 
} 

sub add ( $self ) { 
    my @potentials = map VASP::Pseudo->new( 
            element => $_, 
            xc      => $self->get_xc 
    ), $self->get_args;   
    
    $self->update( @potentials )
} 

sub remove ( $self ) {  
    my @potentials; 

    for my $potential ( $self->get_potentials ) {  
        push @potentials, $potential 
            unless grep $potential->get_element eq $_, $self->get_args
    }
   
    $self->delete; 
    $self->update( @potentials );  
}  

sub order ( $self ) { 
    my @potentials; 

    for my $element ( $self->get_args ) { 
        push @potentials, 
            ( grep $element eq $_->get_element, $self->get_potentials )[0] 
    } 

    $self->delete; 
    $self->update( @potentials );  
} 

sub select ( $self ) { 
    my @potentials; 
    
    for my $potential ( $self->get_potentials ) {  
        if ( grep $potential->get_element eq $_, $self->get_args ) {  
            $potential->clear_config; 
        }

        push @potentials, $potential
    }

    $self->delete; 
    $self->update( @potentials );  
}

sub update ( $self, @potentials ) {  
    for my $potential ( @potentials ) { 
        $self->add_potential( $potential ); 
        $self->print( $potential->get_potcar ); 
    } 
} 

sub info ( $self ) { 
    if ( $self->has_potential ) { 
        print "\nPOTCAR:\n"; 
        for my $potential ( $self->get_potentials ) { 
            $potential->info; 
        }
    } 
} 

sub delete ( $self ) { 
    unlink $self->get_output; 
    $self->clear_potential; 
} 

__PACKAGE__->meta->make_immutable;

1
