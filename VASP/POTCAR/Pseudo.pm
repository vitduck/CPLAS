package VASP::POTCAR::Pseudo;  

use Moose::Role;  
use MooseX::Types::Moose qw/Str ArrayRef/;  
use VASP::Pseudo;  

use namespace::autoclean; 
use experimental 'signatures';  

has 'element', ( 
    is        => 'ro', 
    isa       => ArrayRef, 
    traits    => [ 'Array' ], 
    init_arg  => undef,
    lazy      => 1, 
    builder   => '_build_element', 
    handles   => { get_elements => 'elements' }
); 

has 'potential', ( 
    is        => 'ro', 
    isa       => ArrayRef,  
    traits    => [ 'Array' ], 
    init_arg  => undef,
    lazy      => 1, 
    clearer   => 'clear_potential', 
    builder   => '_build_potential', 
    handles   => { 
        has_potential    => 'count',
        add_potential    => 'push',
        get_potentials   => 'elements' 
    }
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

sub _build_element ( $self ) { 
    $self->info; 
    
    return $self->get_cached( 'element' )
}  

sub _build_potential ( $self ) { 
    if ( -f $self->get_input ) {  
        my @elements = $self->get_cached( 'element' )->@*; 
        my @configs  = $self->get_cached( 'config'  )->@*;  

        return [ 
            map VASP::Pseudo->new( 
                element => $elements[$_],  
                config  => $configs[$_],
                xc      => $self->get_xc 
            ), 0..$#elements
        ]
    } else {  
        return []
    }
} 

1
