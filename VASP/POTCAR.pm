package VASP::POTCAR; 

use Moose;  
use MooseX::Types::Moose qw/ArrayRef/; 
use IO::KISS; 
use VASP::Pseudo; 
use VASP::Types qw/Pseudo/; 
use Periodic::Table qw/Element/; 

use namespace::autoclean; 
use experimental qw/signatures/; 

with qw/IO::Reader IO::Writer/; 
with qw/MooseX::Getopt::Usage/;  

# IO::Reader
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
has 'xc', ( 
    is        => 'ro', 
    isa       => Pseudo, 
    lazy      => 1, 
    reader    => 'get_xc', 
    default   => 'PAW_PBE', 

    documentation => 'XC potential'
); 

has '+extra_argv', ( 
    traits   => [ 'Array' ], 
    handles  => { 
        argv => 'elements'   
    }
); 

has 'element', ( 
    is        => 'ro', 
    isa       => ArrayRef[ Element ],   
    traits    => [ 'Array' ], 
    init_arg  => undef,
    handles   => { 
        add_element  => 'push', 
        has_element  => 'count',
        get_elements => 'elements'
    }
); 

has 'cached_element', ( 
    is        => 'ro', 
    isa       => ArrayRef[ Element ],   
    traits    => [ 'Array' ], 
    lazy      => 1, 
    init_arg  => undef,
    builder   => '_build_cached_element', 
    handles   => { get_cached_elements => 'elements' } 
); 

has 'potcar', ( 
    is        => 'ro', 
    isa       => ArrayRef,
    traits    => [ 'Array' ], 
    init_arg  => undef,
    lazy      => 1, 
    builder   => '_build_potcar', 
    handles   => { get_potcars => 'elements' }, 
); 

sub getopt_usage_config ( $self ) {
    return ( 
        format   => "Usage: %c <make|append> [OPTIONS]", 
        headings => 1
    )
}

sub help ( $self ) { 
    print $self->getopt_usage
} 

sub make ( $self ) { 
    $self->delete;  
    $self->append; 
} 

sub append ( $self ) { 
    $self->help && exit unless $self->has_element; 

    for my $potcar ( $self->get_potcars ) { 
        $self->print( $potcar->slurp ) 
    } 

    $self->info; 
} 

sub info ( $self ) { 
    print "\n=> Summary:\n"; 
    for my $potcar ( $self->get_potcars ) { 
        $potcar->info; 
    } 
} 

sub delete ( $self ) { 
    unlink $self->input; 
} 

sub _build_cached_element ( $self ) { 
    return [ 
        map { ( split /=|:/ )[1] }  
        grep /VRHFIN =(\w+)\s*:/, 
        $self->get_lines 
    ]
} 

sub _build_potcar ( $self ) { 
    return [ 
        map VASP::Pseudo->new( element => $_, xc => $self->get_xc ),  
        grep is_Element( $_ ), 
        $self->get_elements
    ]
}

__PACKAGE__->meta->make_immutable;

1
