package VASP::POTCAR; 

use Moose;  
use MooseX::Types::Moose qw/Str ArrayRef/;  
use VASP::Potential; 
use VASP::Types 'Pseudo'; 
use Data::Printer; 

use namespace::autoclean; 
use feature 'switch'; 
use experimental qw/signatures smartmatch/;  

with 'IO::Reader'; 
with 'IO::Writer'; 
with 'IO::Cache'; 
with 'MooseX::Getopt::Usage';  

# IO::Writer
has '+input', ( 
    init_arg  => undef, 
    default   => 'POTCAR'
); 

# IO::Writer
has '+output', ( 
    init_arg  => undef, 
    default   => 'POTCAR'
); 

has '+o_mode', ( 
    default   => 'a'
); 

# MooseX::Getopt::Usage
has '+extra_argv', ( 
    traits   => [ 'Array' ], 
    handles  => { 
        get_arg  => 'shift', 
        get_args => 'elements'   
    }
); 

# Native 
has 'xc', ( 
    is        => 'ro', 
    isa       => Pseudo, 
    lazy      => 1, 
    reader    => 'get_xc', 
    default   => 'PAW_PBE', 

    documentation => 'XC potential'
); 

has 'element', ( 
    is        => 'ro', 
    isa       => ArrayRef, 
    traits    => [ 'Array' ], 
    init_arg  => undef,
    lazy      => 1, 
    builder   => '_build_elemenet', 
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
        delete_potential => 'delete',
        get_potentials   => 'elements' 
    }
); 

sub BUILD ( $self, @args ) { 
    given ( my $mode = $self->get_arg ) {
        when ( 'info' )                         { $self->info                }
        when ( /make|add|remove|order|select/ ) { $self->$mode; $self->info  }
        default                                 { $self->help                }  
    }
}

sub getopt_usage_config ( $self ) {
    return ( 
        format   => "Usage: %c <info|make|add|remove|order|select> [OPTIONS]", 
        headings => 1
    )
}

sub help ( $self ) { 
    print $self->getopt_usage
} 

sub make ( $self ) {  
    $self->delete; 
    $self->add; 
} 

sub add ( $self ) { 
    my @potentials = map VASP::Potential->new( 
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

sub info ( $self ) { 
    if ( $self->has_potential ) { 
        print "\nPOTCAR:\n"; 
        for my $potential ( $self->get_potentials ) { 
            $potential->info; 
        }
    } 
} 

sub delete ( $self ) { 
    unlink $self->output; 
    $self->clear_potential; 
} 

sub update ( $self, @potentials ) {  
    for my $potential ( @potentials ) { 
        $self->add_potential( $potential ); 
        $self->print( $potential->get_potcar ); 
    } 
} 

sub _build_potential ( $self ) { 
    if ( -f $self->input ) {  
        my @elements = $self->get_cached( 'element' )->@*; 
        my @configs  = $self->get_cached( 'config'  )->@*;  

        return [ 
            map VASP::Potential->new( 
                element => $elements[$_],  
                config  => $configs[$_],
                xc      => $self->get_xc 
            ), 0..$#elements
        ]
    } else {  
        return [ ]
    }
} 

sub _build_cache ( $self ) { 
    my %cache; 

    for ( $self->get_lines ) { 
        push $cache{ element }->@*, $1         if /VRHFIN =(\w+):/; 
        push $cache{ config  }->@*, (split)[3] if /TITEL/; 
    } 

    return \%cache
} 

__PACKAGE__->meta->make_immutable;

1
