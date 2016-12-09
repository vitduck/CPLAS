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

for my $atb ( qw/element config potential/ ) { 
    has $atb, ( 
        is        => 'ro', 
        isa       => ArrayRef,  
        traits    => [ 'Array' ], 
        init_arg  => undef,
        lazy      => 1, 
        default   => sub { [] }, 
        handles   => { 
            'clear_'.$atb      => 'clear',
            'add_'  .$atb      => 'push',
            'get_'  .$atb .'s' => 'elements' 
        }
    )
} 

sub BUILD ( $self, @args ) { 
    # caching 
    if ( -f $self->input ) { 
        $self->cache; 
        
        my @elements = $self->get_cached( 'element' )->@*; 
        my @configs  = $self->get_cached( 'config'  )->@*;  

        $self->add_element( @elements ); 
        $self->add_config ( @configs  ); 

        $self->add_potential( 
            map VASP::Potential->new( 
                element => $elements[$_],  
                config  => $configs[$_],
                xc      => $self->get_xc 
            ), 0..$#elements
        ); 
    }

    # parse cmd
    given ( $self->get_arg ) {
        when ( 'info'   ) { $self->info                      }
        when ( 'make'   ) { $self->make                      }
        when ( 'add'    ) { $self->add   ( $self->get_args ) }
        when ( 'remove' ) { $self->remove( $self->get_args ) }
        when ( 'order'  ) { $self->order ( $self->get_args ) }
        default           { $self->help                      }  
    }
}

sub getopt_usage_config ( $self ) {
    return ( 
        format   => "Usage: %c <info|make|add|remove|reorder> [OPTIONS]", 
        headings => 1
    )
}

sub help ( $self ) { 
    print $self->getopt_usage
} 

sub make ( $self ) {  
    $self->clear; 
    $self->add( $self->get_args )  
} 

sub add ( $self, @elements ) { 
    my @potentials = 
        map VASP::Potential->new( 
            element => $_, 
            xc      => $self->get_xc 
        ), @elements; 

    $self->write( @potentials ); 
    $self->info 
} 

sub remove ( $self, @elements ) { 
    my @new_potentials; 

    for my $potential ( $self->get_potentials ) {  
        push @new_potentials, $potential 
            unless grep $potential->get_element eq $_, $self->get_args
    } 
    
    $self->clear; 
    $self->write( @new_potentials ); 
    $self->info 
}  

sub order( $self, @elements ) { 
    my @new_potentials; 

    for my $element ( @elements ) { 
        push @new_potentials, 
            ( grep $element eq $_->get_element, $self->get_potentials )[0] 
    } 

    $self->clear; 
    $self->write( @new_potentials ); 
    $self->info 
} 

sub info ( $self ) { 
    print "\nPOTCAR:\n"; 
    for my $potential ( $self->get_potentials ) { 
        $potential->info; 
    } 
} 

sub write ( $self, @potentials ) { 
    for ( @potentials ) { 
        $_->select unless $_->get_config; 
        $self->add_potential( $_ ); 
        $self->print( $_->get_potcar ); 
    } 
} 

sub clear ( $self ) { 
    unlink $self->output; 

    $self->clear_element;   
    $self->clear_config;
    $self->clear_potential 
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
