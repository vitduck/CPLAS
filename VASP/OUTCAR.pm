package VASP::OUTCAR; 

use Moose;  
use MooseX::Types::Moose qw/Str Num ArrayRef HashRef RegexpRef/;  

use namespace::autoclean; 
use experimental 'signatures';  

with 'IO::Reader';  
with 'VASP::Spin';  

# IO::Reader
has '+input', ( 
    init_arg  => undef,
    default   => 'OUTCAR' 
);  

# VASP::Spin
has '+magmom', ( 
    handles   => { get_final_magmom => 'get' }
); 

# Native
has 'slurped', ( 
    is        => 'ro', 
    isa       => Str, 
    init_arg  => undef, 
    lazy      => 1, 
    default   => sub { shift->slurp }
); 

has 'energy', ( 
    is        => 'ro', 
    isa       => ArrayRef, 
    traits    => [ 'Array' ], 
    init_arg  => undef, 
    lazy      => 1, 
    builder   => '_build_energy', 
    handles   => { get_energy => [ get => -1 ] }
);  

has '_magmom_regex', ( 
    is        => 'ro', 
    isa       => RegexpRef, 
    init_arg  => undef, 
    lazy      => 1, 
    builder   => '_build_magmom_regex'
); 

has '_energy_regex', ( 
    is        => 'ro', 
    isa       => RegexpRef, 
    init_arg  => undef, 
    lazy      => 1, 
    builder   => '_build_energy_regex'
); 

sub _build_magmom ( $self ) {
    my $magmom = ( $self->slurped =~ /${ \$self->_magmom_regex }/g )[-1]; 

    my @magmom = (
        map { (split)[-1] } 
        IO::KISS->new( \ $magmom, 'r' )->get_lines 
    ); 
    
    # return indexed hash
    return { 
        map { $_ + 1 => $magmom[ $_ ] } 
        0..$#magmom 
    }
} 

sub _build_energy ( $self ) { 
    return [ 
        $self->slurped =~ /${ \$self->_energy_regex }/g 
    ]
} 

sub _build_magmom_regex ( $self ) { 
    return  qr/
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
} 

sub _build_energy_regex ( $self ) { 
    return qr/
        (?:
            free\ \ energy\s+TOTEN\s+=\s+
        )
        (.+?)
        (?:
            \ eV
        )
    /xs
} 

__PACKAGE__->meta->make_immutable;

1 
