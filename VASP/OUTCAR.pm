package VASP::OUTCAR; 

use Moose;  
use MooseX::Types::Moose qw( Str Num ArrayRef HashRef RegexpRef );  
use namespace::autoclean; 
use experimental qw( signatures ); 

with qw( IO::Reader ); 
with qw( VASP::Spin ); 

# IO::Reader
has '+input', ( 
    init_arg  => undef,
    default   => 'OUTCAR' 
);  

# VASP::Spin
has '+magmom', ( 
    handles   => { 
        get_final_magmom => 'get'
    }
); 

# native
has 'content', ( 
    is        => 'ro', 
    isa       => Str, 
    lazy      => 1, 
    init_arg  => undef, 
    default   => sub { $_[0]->_slurp }
); 

has 'energy', ( 
    is        => 'ro', 
    isa       => ArrayRef, 
    traits    => [ 'Array' ], 
    lazy      => 1, 
    init_arg  => undef, 
    builder   => '_build_energy', 
    handles   => { 
        get_energy => [ get => -1 ]
    }
);  

has '_magmom_regex', ( 
    is        => 'ro', 
    isa       => RegexpRef, 
    lazy      => 1, 
    init_arg  => undef, 
    builder   => '_build_magmom_regex'
); 

has '_energy_regex', ( 
    is        => 'ro', 
    isa       => RegexpRef, 
    lazy      => 1, 
    init_arg  => undef, 
    builder   => '_build_energy_regex'
); 

sub _build_magmom ( $self ) {
    my %magmom;  
    my @sblock = ( $self->content =~ /${ \$self->_magmom_regex }/g );  

    for ( IO::KISS->new( \ $sblock[-1], 'r' )->get_lines ) { 
        my ( $index, $magmom ) = ( split )[ 0, -1 ]; 
        $magmom{ $index } = $magmom; 
    }

    return \%magmom; 
} 

sub _build_energy ( $self ) { 
    my @energies = ( $self->content =~ /${ \$self->_energy_regex }/g );  

    return \@energies; 
} 

sub _build_magmom_regex ( $self ) { 
    return (
        qr/
            (?:
                magnetization\ \(x\)\n
                .+?\n
                # of ion\s+s\s+p\s+d\s+tot\n
                -+\n
            )
            (.+?) 
            (?: 
                -+\n
            )
        /xs 
    )
} 

sub _build_energy_regex ( $self ) { 
    return (
        qr/
            (?:
                free\ \ energy\s+TOTEN\s+=\s+
            )
            (.+?)
            (?:
                \ eV
            )
        /xs

    )
} 

__PACKAGE__->meta->make_immutable;

1 
