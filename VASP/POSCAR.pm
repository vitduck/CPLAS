package VASP::POSCAR; 

# core 
use List::Util qw/sum/; 
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
with qw/IO::Proxy Geometry::Basic VASP::Format/;  

# From IO::Proxy
has '+file'  , ( 
    default   => 'POSCAR' 
); 

has '+parser', ( 
    default  => sub ( $self ) { 
        my $poscar = {}; 
        # geometry 
        $poscar->{comment} = $self->get_line; 
        $poscar->{scaling} = $self->get_line; 
        $poscar->{lattice}->@* = map [ split ' ', $self->get_line ], 0..2; 

        # version probe
        my @has_VASP5 = split ' ', $self->get_line; 
        if ( ! grep Element->check($_), @has_VASP5 ) { 
            $poscar->{version} = 4; 
            $poscar->{element} = VASP::POTCAR->new()->element;  
            $poscar->{natom}   = \@has_VASP5;  
            # synchronization 
            $poscar->{element}->@* = 
                splice $poscar->{element}->@*, 0, $poscar->{natom}->@*; 
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
    },  
); 

# From Geometry::Basic
has '+comment', ( 
    default => sub ( $self ) { 
        return $self->parser->{comment} 
    } 
); 

has '+lattice', ( 
    default => sub ( $self ) { 
        return $self->parser->{lattice} 
    } 
); 

has '+element', ( 
    default => sub ( $self ) { 
        return $self->parser->{element} 
    } 
); 

has '+natom', ( 
    default => sub ( $self ) { 
        return $self->parser->{natom} 
    } 
); 

has '+coordinate', ( 
    default => sub ( $self ) { 
        return $self->parser->{coordinate} 
    } 
); 

# Native
has 'version',( 
    is        => 'ro', 
    isa       => Int,  
    init_arg  => undef, 
    lazy      => 1, 
    default   => sub ( $self ) { 
        return $self->parser->{version} 
    } 
);  

has 'scaling', ( 
    is        => 'ro', 
    isa       => Str,   
    init_arg  => undef, 
    lazy      => 1, 
    default   => sub ( $self ) { 
        return $self->parser->{scaling} 
    } 
);  

has 'selective', ( 
    is        => 'ro', 
    isa       => Bool,  
    init_arg  => undef, 
    lazy      => 1, 
    default   => sub ( $self ) { 
        return $self->parser->{selective} 
    } 
); 

has 'type', ( 
    is        => 'ro', 
    isa       => Str, 
    init_arg  => undef, 
    lazy      => 1, 
    default   => sub ( $self ) { 
        return $self->parser->{type} 
    } 
); 

has 'constraint', ( 
    is        => 'ro', 
    isa       => ArrayRef, 
    traits    => ['Array'], 
    init_arg  => undef, 
    lazy      => 1, 
    default   => sub ( $self ) { 
        return $self->parser->{constraint} 
    }, 
    handles   => { 
        get_constraint => 'shift', 
        get_constraints => 'elements' 
    } 
); 

has 'false_indices', ( 
    is        => 'ro', 
    isa       => ArrayRef, 
    traits    => ['Array'], 
    lazy      => 1, 
    init_arg  => undef,
    default   => sub ( $self ) { 
        my @constraints = $self->get_constraints; 
        my %indices     = %constraints[0..$#constraints]; 
        return [ grep { grep { $_ eq 'F' } $indices{$_}->@* } sort { $a <=> $b } keys %indices ] 
    }, 
    handles   => { 
        get_false_index   => 'shift', 
        get_false_indices => 'elements', 
    }, 
); 

has 'true_indices', ( 
    is        => 'ro', 
    isa       => ArrayRef, 
    traits    => ['Array'], 
    lazy      => 1, 
    init_arg  => undef,
    default   => sub ( $self ) { 
        my @true_indices = (); 
        my @constraints  = $self->get_constraints; 
        # intersection between true and false indices 
        for my $index ( 0..$#constraints ) { 
            if ( grep $index eq $_, $self->get_false_indices ) { next } 
            push @true_indices, $index; 
        }
        return \@true_indices; 
    }, 
    handles   => { 
        get_true_index   => 'shift', 
        get_true_indices => 'elements', 
    }, 
);  

has 'save', ( 
    is      => 'ro', 
    isa     => Bool, 
    lazy    => 1, 
    default => 0, 
    trigger => sub ( $self, @args ) { 
        $self->save_original_poscar; 
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

sub write ( $self ) { 
    $self->write_vasp_lattice; 
    $self->write_vasp_element; 
    $self->write_vasp_coordinate; 
    $self->close; 
} 

sub write_vasp_lattice ( $self ) { 
    $self->printf("%s\n", $self->comment); 
    $self->printf($self->get_format('scaling'), $self->scaling); 
    $self->printf($self->get_format('lattice'), @$_) for $self->get_lattices;  
} 

sub write_vasp_element ( $self ) { 
    $self->printf($self->get_format('element'), $self->get_elements) if $self->version == 5;  
    $self->printf($self->get_format('natom'),  $self->get_natoms); 
}

sub write_vasp_coordinate ( $self ) { 
    # constructing geometry block 
    my @table = 
        $self->selective ? 
        map [ 
            $self->coordinate->[$_]->@*, $self->constraint->[$_]->@*, $_+1 
        ], 0..$self->total_natom-1:  
        map [ 
            $self->coordinate->[$_]->@*, $_+1 
        ], 0..$self->total_natom-1;  

    $self->printf("%s\n", 'Selective Dynamics') if $self->selective;  
    $self->printf("%s\n", $self->type); 

    $self->printf($self->get_format('coordinate'), @$_) for @table; 
} 

sub save_original_poscar ( $self ) { 
    copy $self->file => $self->save_as;  
} 

sub BUILD ( $self, @args ) { 
    # parse POSCAR and cache 
    try { $self->parser };  
} 

# speed-up object construction 
__PACKAGE__->meta->make_immutable;

1; 
