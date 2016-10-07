package VASP::OUTCAR; 

use Moose;  
use MooseX::Types::Moose qw( Str Num HashRef RegexpRef );  
use namespace::autoclean; 
use experimental qw( signatures ); 

with qw( IO::Reader ); 
with qw( VASP::Spin ); 

has '+input', ( 
    init_arg  => undef,
    default   => 'OUTCAR' 
);  

has '+magmom', ( 
    handles   => { 
        get_final_magmom => 'get'
    }
); 

has '_magmom_regex', ( 
    is        => 'ro', 
    isa       => RegexpRef, 
    lazy      => 1, 
    init_arg  => undef, 
    builder   => '_build_magmom_regex'
); 

sub _build_magmom_regex ( $self ) { 
    return 
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
} 

sub _build_magmom ( $self ) {
    my %magmom;  
    my @sblock = ( $self->_slurp =~ /${ \$self->_magmom_regex }/g );  

    for ( IO::KISS->new( \ $sblock[-1], 'r' )->get_lines ) { 
        my ( $index, $magmom ) = ( split )[ 0, -1 ]; 
        $magmom{ $index } = $magmom; 
    }

    return \%magmom; 
} 

__PACKAGE__->meta->make_immutable;

1 
