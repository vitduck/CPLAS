package VASP::POTCAR; 

use Moose;  
use MooseX::Types::Moose qw( Str ArrayRef HashRef ); 
use Moose::Util::TypeConstraints qw( enum );  
use namespace::autoclean; 

use File::Basename; 
use File::Spec::Functions; 
use IO::KISS;  
use Periodic::Table qw( Element Element_Name ); 

use feature qw( signatures refaliasing );  
use experimental qw( signatures refaliasing ); 

with qw( 
    IO::Reader 
    IO::Writer 
    IO::Cache 
); 

has 'pot_dir', ( 
    is        => 'ro', 
    isa       => Str, 
    lazy      => 1, 
    init_arg  => undef, 
    default   => $ENV{ POT_DIR }, 
); 

has 'file', ( 
    is        => 'ro', 
    isa       => Str, 
    lazy      => 1, 
    init_arg  => undef, 
    default   => 'POTCAR', 
); 

has 'element', ( 
    is        => 'ro', 
    isa       => ArrayRef[ Element ],  
    traits    => [ qw( Array ) ], 
    predicate => 'has_element', 

    handles   => { 
        _add_element => 'push', 
        get_elements => 'elements' 
    } 
); 

has 'exchange', ( 
    is        => 'ro', 
    isa       => enum( [ qw( PAW_PBE PAW_GGA PAW_LDA POT_GGA POT_LDA ) ] ),  
    writer    => '_set_exchange', 
); 

has 'potcar', ( 
    is        => 'ro', 
    isa       => HashRef, 
    traits    => [ qw( Hash ) ], 
    init_arg  => undef, 

    handles   => { 
        _set_potcar => 'set', 
        _get_potcar => 'get'
    }  
); 

sub BUILD ( $self, @ ) { 
    # check if potential directory is accessible 
    if ( not -d $self->pot_dir ) { 
        die "Please export location of POTCAR files in .bashrc\n
        For example: export POT_DIR=/opt/VASP/POTCAR\n";
    }
} 

sub make ( $self ) { 
    $self->clear; 
    $self->append( $self->_get_elements ); 
    $self->_close_writer; 
    $self->_clear_writer; 
} 

sub append ( $self, @elements ) { 
    for my $element ( @elements ) {     
        $self->select( $element ); 
        $self->_print( $self->_get_potcar( $element ) ) 
    } 
} 

sub select ( $self, $element ) { 
    my @configs = $self->_list_potcar_configs( $element );  
    my $potcar  = $self->_select_potcar_config( @configs ); 

    $self->_set_potcar( 
        $element => IO::KISS->new( 
            file   => $potcar,
            mode   => 'r', 
            _chomp => 1 
        )->slurp 
    )
} 

sub clear ( $self ) { 
    unlink $self->file 
} 

sub _list_potcar_configs ( $self, $element ) { 
    return 
        map basename( $_ ), 
        grep /\/($element)(\z|\d|_|\.)/, 
        glob "${ \$self->pot_dir }/${ \$self->exchange }/*"; 
} 

sub _select_potcar_config ( $self, @configs ) {  
    while ( 1 ) { 
        # prompt 
        printf "=> Pseudopotentials < %s >: ", join(' | ', @configs );  
        chomp ( my $choice = <STDIN> =~ s/\s+//rg ); 
        
        if ( grep $choice eq $_ , @configs ) { 
            return catfile( $self->pot_dir, $self->exchange, $choice, 'POTCAR' ) 
        }
    }
} 

# IO:Reader
sub _build_reader ( $self ) { 
    return IO::KISS->new( 
        file   => $self->file, 
        mode   => 'r',
        _chomp => 1 
    ) 
} 

# IO:Writer ( append mode )
sub _build_writer ( $self ) { 
    return IO::KISS->new( 
        file   => $self->file, 
        mode   => 'a' 
    ) 
} 

# IO::Cache
sub _build_cache ( $self ) { 
    my %info; 
    my @elements; 
    my ( $exchange, $element, $pseudo, $config, $date ); 

    for ( $self->_get_lines ) { 
        # Ex: VRHFIN =C: s2p2
        if ( /VRHFIN =(\w+)\s*:(.*)/ ) { 
            $element = $1; 
            my @valences = ( $2 =~ /([spdf]\d+)/g ); 

            $config  =  
                @valences  
                ? join '', @valences 
                : ( split ' ', $2 )[ 0 ]; 

            push @elements, $element; 
        }

        # Ex: TITEL  = PAW_PBE C_s 06Sep2000
        if ( /TITEL/ ) { 
            ( $exchange, $pseudo, $date ) = ( split )[ 2..4 ]; 
            push $info{$exchange}->@*, 
                [ to_Element_Name( $element ), $pseudo, $config, $date //= '---' ]; 
        }
    }

    $self->_set_exchange( $exchange ); 
    $self->_add_element( @elements ); 

    $self->_close_reader; 

    return \%info;  
} 

__PACKAGE__->meta->make_immutable;

1
