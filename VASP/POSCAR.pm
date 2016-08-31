package VASP::POSCAR; 

# core 
use List::Util qw/sum/; 
use File::Copy qw/copy/;  

# cpan
use Moose;  
use MooseX::Types::Moose qw/Bool Str Int ArrayRef HashRef/;  
use namespace::autoclean; 

# pragma
use autodie; 
use warnings FATAL => 'all'; 
use experimental qw/signatures postderef_qq/; 

# Moose type
use VASP::Periodic qw/Element/; 

# Moose class 
use VASP::POTCAR; 

# Moose role
with qw/VASP::Geometry VASP::IO/;  

# Moose attribute  
# From VASP::IO
has '+file', (  
    required  => 1, 
); 

has '+parse', ( 
    lazy     => 1, 
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

# From VASP::Geometry
for my $name ( qw/comment element natom lattice coordinate/ ) { 
    has '+'.$name, (  
        default   => sub ( $self ) { return $self->extract($name) }
    ); 
} 

has 'total_natom', ( 
    is        => 'ro', 
    isa       => Int, 
    init_arg  => undef, 
    lazy      => 1, 
    default   => sub ( $self ) { 
        return sum($self->get_natoms) 
    }
); 

has 'version', ( 
    is        => 'ro', 
    isa       => Int, 
    lazy      => 1, 
    default   => sub ( $self ) { 
        return $self->extract('version') 
    },   
); 

has 'scaling', ( 
    is        => 'ro', 
    isa       => Str, 
    lazy      => 1,  
    default   => sub ( $self ) { 
        return $self->extract('scaling') 
    },   
); 

has 'selective', ( 
    is        => 'ro', 
    isa       => Bool, 
    lazy      => 1, 
    default   => sub ( $self ) { 
        return $self->extract('selective') 
    } 
); 

has 'type', ( 
    is        => 'ro', 
    isa       => Str, 
    lazy      => 1,  
    default   => sub ( $self ) { 
        return $self->extract('type') 
    }
); 

has 'constraint', ( 
    is       => 'ro', 
    isa      => ArrayRef, 
    traits   => ['Array'], 
    lazy     => 1,
    default  => sub ( $self ) { 
        return $self->extract('constraint') 
    },  
    handles  => { 
        get_constrain  => 'shift', 
        get_constrains => 'elements', 
    } 
); 

has 'coordinate_format', ( 
    is       => 'ro', 
    isa      => Str, 
    lazy     => 1, 
    default  => sub ( $self ) { 
        return 
            $self->selective ? 
            "%22.16f%22.16f%22.16f%5s%5s%5s%6d\n" :  
            "%22.16f%22.16f%22.16f%6d\n"
    } 
); 

sub write ( $self ) { 
    $self->write_vasp_lattice; 
    $self->write_vasp_element; 
    $self->write_vasp_coordinate; 
} 

sub write_vasp_lattice ( $self ) { 
    $self->printf("%s\n", $self->comment); 
    $self->printf("%f\n", $self->scaling); 
    $self->printf("%22.16f%22.16f%22.16f\n", @$_) for $self->get_lattices;  
} 

sub write_vasp_element ( $self ) { 
    $self->printf("%s\n", (join "\t", $self->get_elements)) if $self->version == 5;  
    $self->printf("%s\n", (join "\t", $self->get_natoms));  
}

sub write_vasp_coordinate ( $self ) { 
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
    $self->printf($self->coordinate_format, @$_) for @table; 
} 

sub backup ( $self ) { 
    copy $self->file => ${\$self->file}.'old'; 
} 

# speed-up object construction 
__PACKAGE__->meta->make_immutable;

1; 
