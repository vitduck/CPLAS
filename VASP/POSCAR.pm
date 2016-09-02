package VASP::POSCAR; 

# core 
use File::Copy qw/copy/;  

# cpan
use Moose;  
use MooseX::Types::Moose qw/Bool Str Int ArrayRef HashRef/;  
use Try::Tiny; 
use namespace::autoclean; 

# pragma
use warnings FATAL => 'all'; 
use experimental qw/signatures postderef_qq/;  

# Moose type
use Periodic::Element qw/Element/;  

# Moose class 
use VASP::POTCAR; 

# Moose role
with qw/IO::Proxy Geometry::Template VASP::Format/;  

# From IO::Proxy
has '+file'  , ( 
    default   => 'POSCAR' 
); 

has '+parser', ( 
    lazy     => 1, 
    builder  => '_parse_POSCAR', 
); 

# From Geometry::Template
has '+comment', ( 
    default => sub ( $self ) { 
        return $self->parser->{comment} 
    } 
); 

has '+lattice', ( 
    lazy    => 1, 
    default => sub ( $self ) { 
        return $self->parser->{lattice} 
    } 
); 

has '+element', ( 
    lazy    => 1, 
    default => sub ( $self ) { 
        return $self->parser->{element} 
    } 
); 

has '+natom', ( 
    lazy    => 1, 
    default => sub ( $self ) { 
        return $self->parser->{natom} 
    } 
); 

has '+coordinate', ( 
    lazy    => 1, 
    default => sub ( $self ) { 
        return $self->parser->{coordinate} 
    } 
); 

# Native
has 'version',( 
    is        => 'ro', 
    isa       => Int,  
    lazy      => 1, 
    default   => sub ( $self ) { 
        return $self->parser->{version} 
    } 
);  

has 'scaling', ( 
    is        => 'ro', 
    isa       => Str,   
    lazy      => 1, 
    default   => sub ( $self ) { 
        return $self->parser->{scaling} 
    } 
);  

has 'selective', ( 
    is        => 'ro', 
    isa       => Bool,  
    lazy      => 1, 
    default   => sub ( $self ) { 
        return $self->parser->{selective} 
    } 
); 

has 'type', ( 
    is        => 'ro', 
    isa       => Str, 
    lazy      => 1, 
    default   => sub ( $self ) { 
        return $self->parser->{type} 
    } 
); 

has 'constraint', ( 
    is        => 'rw', 
    isa       => ArrayRef, 
    traits    => ['Array'], 
    init_arg  => undef, 
    lazy      => 1, 
    default   => sub ( $self ) { 
        return $self->parser->{constraint} 
    }, 
    handles   => { 
        set_constraint  => 'set', 
        get_constraints => 'elements', 
    } 
); 

has 'index', ( 
    is        => 'ro', 
    isa       => ArrayRef, 
    traits    => ['Array'], 
    init_arg  => undef, 
    lazy      => 1, 
    default   => sub ( $self ) { 
        return [ 0..$self->total_natom-1 ] 
    }, 
    handles   => { 
        get_indices => 'elements', 
    },  
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

has 'false_index', ( 
    is        => 'ro', 
    isa       => ArrayRef, 
    traits    => ['Array'], 
    lazy      => 1, 
    init_arg  => undef,
    builder   => '_build_false_index', 
    handles   => { 
        get_false_indices => 'elements', 
    }, 
); 

has 'true_index', ( 
    is        => 'ro', 
    isa       => ArrayRef, 
    traits    => ['Array'], 
    lazy      => 1, 
    init_arg  => undef,
    builder   => '_build_true_index', 
    handles   => { 
        get_true_indices => 'elements', 
    }, 
);  


has 'dynamics', (   
    is        => 'ro', 
    isa       => ArrayRef, 
    lazy      => 1, 
    default   => sub ( $self ) { 
        return [ qw/T T T/ ]
    },  
    trigger   => sub ( $self, @args ) { 
        $self->_modify_constraint; 
    } 
); 

has 'save', ( 
    is      => 'ro', 
    isa     => Bool, 
    lazy    => 1, 
    default => 0, 
    trigger => sub ( $self, @args ) { 
        $self->_backup; 
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

#----------------#
# Public Method  #
#----------------#
sub write ( $self ) { 
    # atomic indices 
    my @indices = $self->get_indices; 

    # constructing geometry block 
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
    
    $self->close; 
} 

sub BUILD ( $self, @args ) { 
    # cache POSCAR
    try { $self->parser };  
} 

#----------------#
# Private Method #
#----------------#
sub _parse_POSCAR ( $self ) { 
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

sub _build_false_index ( $self ) { 
    my @false   = (); 

    for my $index ( $self->get_indices ) { 
        if ( grep $_ eq 'F', $self->constraint->[$index]->@* ) { 
            push @false, $index 
        }
    }

    return \@false; 
} 

sub _build_true_index ( $self ) { 
    my @true = (); 

    for my $index ( $self->get_indices ) { 
        if ( grep $index eq $_, $self->get_false_indices ) { next } 
        push @true, $index; 
    }
    return \@true; 
} 

# Using Coercing is better ? 
# For both component and index
sub _modify_constraint ( $self ) {     
    for my $index ( $self->get_sub_indices ) { 
        # off-set by 1 
        $self->set_constraint( --$index, $self->dynamics ); 
    } 
} 

sub _backup ( $self ) { 
    copy $self->file => $self->save_as;  
} 


# speed-up object construction 
__PACKAGE__->meta->make_immutable;

1; 
