package VASP::POTCAR; 

use Moose;  
use MooseX::Types::Moose qw( Undef Str ArrayRef HashRef ); 
use Moose::Util::TypeConstraints qw( enum );  

use File::Basename; 
use File::Spec::Functions; 

use IO::KISS;  
use Periodic::Table qw( Element Element_Name ); 

use namespace::autoclean; 
use feature qw( signatures refaliasing );  
use experimental qw( signatures refaliasing ); 

with qw( IO::Reader IO::Writer IO::Cache ); 

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
    is        => 'rw', 
    isa       => ArrayRef,  
    traits    => [ qw( Array ) ], 
    lazy      => 1, 
    predicate => '_has_element', 
    builder   => '_build_element', 

    handles   => { 
        _add_element  => 'push', 
        _get_elements => 'elements' 
    } 
); 

has 'exchange', ( 
    is        => 'rw', 
    isa       => enum( [ qw( PAW_PBE PAW_GGA PAW_LDA POT_GGA POT_LDA ) ] ),  
    lazy      => 1, 
    builder   => '_build_exchange',  
    clearer   => '_clear_exchange'
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
    unless ( -d $self->pot_dir ) { 
        die "Please export location of POTCAR files in .bashrc\n
        For example: export POT_DIR=/opt/VASP/POTCAR\n";
    }

    # cache POTCAR 
    $self->cache if -f $self->file 
} 

sub info ( $self ) { 
    # ArrayRef
    my $info = $self->_get_cached( $self->exchange );  

    printf  "\n=> Pseudopotential: %s\n", $self->exchange;  
    printf "%-10s %-6s %-10s %-s\n", @$_ for $info->@*;  
} 

sub make ( $self ) { 
    # delete existed POTCAR 
    $self->delete; 

    $self->append( $self->_get_elements ); 
    $self->info; 
} 

sub append ( $self, @elements ) { 
    for ( grep is_Element( $_ ), @elements ) {  
        $self->select( $_ ); 
        $self->_print( 
            IO::KISS->new( 
                file   => $self->_get_potcar( $_ ), 
                mode   => 'r', 
                _chomp => 1 
            )->slurp 
        )
    } 

    $self->refresh; 
} 

sub select ( $self, $element ) { 
    my @configs = $self->_list_potcar_configs( $element );  
    my $potcar  = $self->_select_potcar_config( @configs ); 
    
    # populate potcar HashRef
    $self->_set_potcar( $element => $potcar ); 
} 

sub refresh ( $self ) { 
    $self->_clear_exchange; 
    $self->_clear_reader; 
    $self->_clear_writer; 
    $self->_clear_cache; 
} 

sub delete ( $self ) { 
    unlink $self->file 
} 

sub _build_exchange ( $self ) { 
    my @exchanges = $self->_list_cached;   

    return 
        @exchanges > 1
        ? die "Error: Mixed POTCAR @exchanges...\n"
        : shift @exchanges; 
} 

sub _build_element ( $self ) { 
    my $info = $self->_get_cached( $self->exchange );  

    return [ map to_Element( $_->[ 0 ] ), $info->@* ] 
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
    my ( $exchange, $element, $pseudo, $valence, $date ); 

    for ( $self->_get_lines ) { 
        chomp; 
        # Ex: VRHFIN =C: s2p2
        if ( /VRHFIN =(\w+)\s*:(.*)/ ) { 
            $element = $1; 
            my @split_valences = ( $2 =~ /([spdf]\d+)/g ); 

            $valence  =  
                @split_valences  
                ? join '', @split_valences 
                : ( split ' ', $2 )[ 0 ]; 
        }

        # Ex: TITEL  = PAW_PBE C_s 06Sep2000
        if ( /TITEL/ ) { 
            ( $exchange, $pseudo, $date ) = ( split )[ 2..4 ]; 

            push $info{ $exchange }->@*, 
                [ to_Element_Name( $element ), $pseudo, $valence, $date //= '---' ]; 
        }
    }

    $self->_close_reader; 

    return \%info;  
} 

__PACKAGE__->meta->make_immutable;

1
