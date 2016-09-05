package VASP::POSCAR; 

use Moose;  
use MooseX::Types::Moose qw/Bool Str Int ArrayRef HashRef/;  
use File::Copy qw/copy/;  
use Try::Tiny; 

use strictures 2; 
use namespace::autoclean; 
use experimental qw/signatures postderef_qq/;  

use VASP::POTCAR; 
use Periodic::Table qw/Element/;  
with qw/VASP::Format IO::RW Geometry::Share Geometry::VASP/ ;  

# From IO::Proxy
has '+file'  , ( 
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

has 'save', ( 
    is      => 'ro', 
    isa     => Bool, 
    lazy    => 1, 
    default => 0, 

    trigger => sub ( $self, @args ) { 
        copy $self->file => $self->save_as;  
    } 
); 

has 'save_as', ( 
    is      => 'ro', 
    isa     => Str, 
    lazy    => 1, 

    default => sub ( $self ) { 
        return join('.', $self->file, 'original'); 
    } 
); 

# cache POSCAR
sub BUILD ( $self, @args ) { 
    try { $self->parser };  
} 

sub write ( $self ) { 
    # constructing geometry block 
    my @indices = $self->get_indices; 
    my @table = 
        $self->selective ? 
        map [ $self->coordinate->[$_]->@*, $self->constraint->[$_]->@*, $_+1 ], @indices : 
        map [ $self->coordinate->[$_]->@*, $_+1 ], @indices; 

    # write to POSCAR 
    $self->printf("%s\n", $self->comment); 
    $self->printf($self->get_format('scaling'), $self->scaling); 
    $self->printf($self->get_format('lattice'), @$_) for $self->get_lattices;  
    $self->printf($self->get_format('element'), $self->get_elements) if $self->version == 5;  
    $self->printf($self->get_format('natom'),   $self->get_natoms); 
    $self->printf("%s\n", 'Selective Dynamics') if $self->selective;  
    $self->printf("%s\n", $self->type); 
    $self->printf($self->get_format('coordinate'), @$_) for @table; 
    $self->close_fh; 
} 

sub _parse_file ( $self ) { 
    my $poscar = {}; 
    # geometry 
    $poscar->{comment} = $self->get_line; 
    $poscar->{scaling} = $self->get_line; 
    $poscar->{lattice}->@* = map [ split ' ', $self->get_line ], 0..2; 

    # version probe
    my @has_VASP5 = split ' ', $self->get_line; 
    if ( ! grep Element->check($_), @has_VASP5 ) { 
        $poscar->{version} = 4; 
        # get elements from POTCAR and synchronize with @natoms
        $poscar->{element} = [ VASP::POTCAR->new()->get_elements ]; 
        $poscar->{natom}   = \@has_VASP5;  
        $poscar->{element}->@* = splice $poscar->{element}->@*, 0, $poscar->{natom}->@*; 
    } else { 
        $poscar->{version} = 5; 
        $poscar->{element} = \@has_VASP5; 
        $poscar->{natom}   = [ split ' ', $self->get_line ]; 
    } 

    # selective dynamics 
    my $has_selective = $self->get_line;  
    if ( $has_selective =~ /^\s*S/i ) { 
        $poscar->{selective} = 1; 
        $poscar->{type}      = $self->get_line; 
    } else { 
        $poscar->{selective} = 0; 
        $poscar->{type}      = $has_selective; 
    } 

    # coodinate 
    while ( local $_ = $self->get_line ) { 
        if ( /^\s+$/ ) { last } 
        my @columns = split; 

        # 1st 3 columns are coordinate 
        push $poscar->{coordinate}->@*, [ splice @columns, 0, 3 ];  

        # if remaining column is either 0 or 1 (w/o indexing) 
        # the POSCAR contains no selective dynamics block 
        push $poscar->{constraint}->@*, (
            @columns == 0 || @columns == 1 ? 
            [ qw/T T T/ ] :
            [ splice @columns, 0, 3 ]
        ); 
    } 
    return $poscar; 
} 

__PACKAGE__->meta->make_immutable;

1; 
