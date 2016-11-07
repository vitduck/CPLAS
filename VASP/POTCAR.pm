package VASP::POTCAR; 

use Moose;  
use MooseX::Types::Moose qw( Undef Str ArrayRef HashRef ); 
use IO::KISS; 
use Periodic::Table qw( Element Element_Name ); 
use VASP::Types qw( Pseudo ); 
use File::Basename; 
use File::Spec::Functions; 
use namespace::autoclean; 
use feature qw( signatures refaliasing );  
use experimental qw( signatures refaliasing ); 

with qw( IO::Reader ); 
with qw( IO::Writer ); 
with qw( MooseX::Getopt::Usage ); 

# Getopt
has 'xc', ( 
    is        => 'ro', 
    isa       => Pseudo, 
    lazy      => 1, 
    predicate => '_has_xc', 
    writer    => '_set_xc', 
    default   => 'PAW_PBE', 

    documentation => 'XC potential'
); 

has '+extra_argv', ( 
    traits   => [ qw( Array ) ], 
    handles  => { 
        argv => 'elements'   
    }
); 

# IO::Reader
has '+input', ( 
    init_arg  => undef, 
    default   => 'POTCAR'
); 

has '+cache', ( 
    handles => { 
        list_xc => 'keys', 
        get_pp  => 'get', 
    }
); 

# IO::Writer
has '+output', ( 
    init_arg  => undef, 
    default   => 'POTCAR'
); 

has '+o_mode', ( 
    default   => 'a'
); 

# native
has 'pot_dir', ( 
    is        => 'ro', 
    isa       => Str, 
    init_arg  => undef, 
    default   => $ENV{ POT_DIR }, 
); 

has 'element', ( 
    is        => 'ro', 
    isa       => ArrayRef[ Element ],   
    traits    => [ qw( Array ) ], 
    init_arg  => undef,
    handles   => { 
        no_element   => 'is_empty', 
        add_element  => 'push', 
        get_elements => 'elements', 
    }, 
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
} 
sub getopt_usage_config ( $self ) {
    return 
        format   => "Usage: %c <make|append|info> [OPTIONS]", 
        headings => 1
}

sub info ( $self, $verbose = 1 ) { 
    # cache POTCAR
    -f $self->input ? $self->cache : return; 

    # list of xc
    my @xcs = $self->list_xc; 

    # print info
    for my $xc ( @xcs ) {
        printf "\n=> Pseudopotential: %s\n", $xc if $verbose;  

        for my $pp ( $self->get_pp( $xc )->@* ) {
            $self->add_element( to_Element( $pp->[0] ) );  
            printf "%-10s %-6s %-10s %-s\n", $pp->@* if $verbose;  
        } 
    }

    # set exchange
    @xcs > 1 
    ? die "\n=> Error: Mixing different exchanges in POTCAR\n" 
    : $self->_set_xc( shift @xcs ); 
} 

sub make ( $self ) { 
    # delete existed POTCAR 
    $self->delete; 

    $self->append( $self->get_elements ) unless $self->no_element; 
} 

sub append ( $self, @elements ) { 
    return unless @elements; 

    for ( grep is_Element( $_ ), @elements ) {  
        $self->cache_potcar( $_ ); 
        $self->_print( $self->_get_potcar( $_) ); 
    } 

    $self->refresh; 
    $self->info; 
} 

sub refresh ( $self ) { 
    $self->_clear_reader; 
    $self->_clear_writer; 
    $self->_clear_cache; 
} 

sub delete ( $self ) { 
    unlink $self->input; 
} 

sub cache_potcar ( $self, $element ) { 
    my @configs = $self->list_potcar( $element );  
    
    # populate potcar HashRef
    $self->_set_potcar( 
        $element => IO::KISS->new( 
            file   => $self->select_potcar( @configs ),  
            mode   => 'r', 
            _chomp => 1 
        )->slurp 
    ); 
} 

sub list_potcar( $self, $element ) { 
    return 
        map basename( $_ ), 
        grep /\/($element)(\z|\d|_|\.)/, 
        glob "${ \$self->pot_dir }/${ \$self->xc }/*"; 
} 

sub select_potcar ( $self, @configs ) {  
    while ( 1 ) { 
        # prompt 
        printf "=> Pseudopotentials < %s >: ", join(' | ', @configs );  
        chomp ( my $choice = <STDIN> =~ s/\s+//rg ); 
        
        if ( grep $choice eq $_ , @configs ) { 
            return catfile( $self->pot_dir, $self->xc, $choice, 'POTCAR' ) 
        }
    }
} 

sub _build_cache ( $self ) { 
    my %info; 
    my ( $exchange, $element, $pseudo, $valence, $date ); 
    my @split_valences; 

    for ( $self->_get_lines ) { 
        chomp; 
        # Ex: VRHFIN =C: s2p2
        if ( /VRHFIN =(\w+)\s*:(.*)/ ) { 
            $element = $1; 
            @split_valences = ( $2 =~ /([spdf]\d+)/g ); 

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
