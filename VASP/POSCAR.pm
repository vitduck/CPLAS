package VASP::POSCAR; 

use Moose;  
use MooseX::Types::Moose qw/Str Int ArrayRef HashRef/;  
use File::Copy qw/copy/;  
use Try::Tiny; 

use strictures 2; 
use namespace::autoclean; 
use experimental qw/signatures postderef_qq/;  

use IO::KISS; 
use VASP::POTCAR; 
use Periodic::Table qw/Element/;  

with qw/VASP::Format/, 
     qw/IO::Parser/, 
     qw/ Geometry::Share Geometry::VASP/;  

# From IO::Proxy
has 'file', ( 
    is        => 'ro', 
    isa       => Str, 
    lazy      => 1, 
    default   => 'POSCAR' 
); 

has 'sub_index', ( 
    is        => 'ro', 
    isa       => ArrayRef, 
    traits    => ['Array'], 
    lazy      => 1, 

    default   => sub ( $self ) { 
        return $self->index; 
    },  

    handles   => { 
        get_sub_indices => 'elements', 
    },  
); 

has 'dynamics', (   
    is        => 'ro', 
    isa       => ArrayRef, 
    lazy      => 1, 

    default   => sub ( $self )  { 
        return [ qw/T T T/ ] 
    }, 

    trigger   => sub ( $self, @args ) { 
        $self->set_constraint( 
            # off-set by 1
            map { --$_ => $self->dynamics } $self->get_sub_indices 
        ) 
    },  
); 

has 'backup', ( 
    is        => 'ro', 
    isa       => Str, 
    lazy      => 1, 
    default   => 0, 

    trigger => sub ( $self, @args ) { 
        copy $self->file => $self->backup; 
    } 
); 

has 'save_as', ( 
    is        => 'ro', 
    isa       => Str, 
    lazy      => 1, 
    predicate => 'has_save_as', 
    default => 'POSCAR.new', 
); 

# cache POSCAR
sub BUILD ( $self, @args ) { 
    try { $self->parser };  
} 

sub write ( $self ) { 
    # if save_as is not set, overwrite the original POSCAR 
    my $fh = 
        $self->has_save_as ? 
        IO::KISS->new( $self->save_as, 'w' ) :  
        IO::KISS->new( $self->file, 'w' ); 

    # constructing geometry block 
    my @indices = $self->get_indices; 
    my @table = 
        $self->selective ? 
        map [ $self->get_coordinate($_)->@*, $self->get_constraint($_)->@*, $_+1 ], @indices : 
        map [ $self->coordinate->[$_]->@*, $_+1 ], @indices; 

    # write to POSCAR 
    $fh->printf("%s\n", $self->comment); 
    $fh->printf($self->get_format('scaling'), $self->scaling); 
    $fh->printf($self->get_format('lattice'), @$_) for $self->get_lattices;  
    $fh->printf($self->get_format('element'), $self->get_elements) if $self->version == 5;  
    $fh->printf($self->get_format('natom'),   $self->get_natoms); 
    $fh->printf("%s\n", 'Selective Dynamics') if $self->selective;  
    $fh->printf("%s\n", $self->type); 
    $fh->printf($self->get_format('coordinate'), @$_) for @table; 
    
    $fh->close; 
} 

sub _parse_file ( $self ) { 
    my $poscar = {}; 

    my $fh = IO::KISS->new($self->file, 'r'); 
    
    # geometry 
    $poscar->{comment} = $fh->get_line; 
    $poscar->{scaling} = $fh->get_line; 
    $poscar->{lattice}->@* = map [ split ' ', $fh->get_line ], 0..2; 

    # version probe
    my @has_VASP5 = split ' ', $fh->get_line; 
    if ( ! grep Element->check($_), @has_VASP5 ) { 
        $poscar->{version} = 4; 
        # get elements from POTCAR and synchronize with @natoms
        $poscar->{element} = [ VASP::POTCAR->new()->get_elements ]; 
        $poscar->{natom}   = \@has_VASP5;  
        $poscar->{element}->@* = splice $poscar->{element}->@*, 0, $poscar->{natom}->@*; 
    } else { 
        $poscar->{version} = 5; 
        $poscar->{element} = \@has_VASP5; 
        $poscar->{natom}   = [ split ' ', $fh->get_line ]; 
    } 

    # selective dynamics 
    my $has_selective = $fh->get_line;  
    if ( $has_selective =~ /^\s*S/i ) { 
        $poscar->{selective} = 1; 
        $poscar->{type}      = $fh->get_line; 
    } else { 
        $poscar->{selective} = 0; 
        $poscar->{type}      = $has_selective; 
    } 

    # coodinate and constraint
    my $index = 0;   
    while ( local $_ = $fh->get_line ) { 
        last if /^\s+$/; 

        my @columns = split; 
        # 1st 3 columns are coordinate 
        $poscar->{coordinate}->{$index} = [ splice @columns, 0, 3 ];  

        # if remaining column is either 0 or 1 (w/o indexing) 
        # the POSCAR contains no selective dynamics block 
        $poscar->{constraint}->{$index} = (
            @columns == 0 || @columns == 1 ? 
            [ qw/T T T/ ] :
            [ splice @columns, 0, 3 ]
        ); 

        $index++; 
    } 

    $fh->close; 

    return $poscar; 
} 

__PACKAGE__->meta->make_immutable;

1; 
