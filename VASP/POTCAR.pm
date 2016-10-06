package VASP::POTCAR; 

use Moose;  
use MooseX::Types::Moose qw( Undef Str ArrayRef HashRef ); 
use IO::KISS; 
use Periodic::Table qw( Element ); 
use VASP::Pseudo qw( Pseudo ); 
use File::Basename; 
use File::Spec::Functions; 
use namespace::autoclean; 
use feature qw( signatures refaliasing );  
use experimental qw( signatures refaliasing ); 

with qw( MooseX::Getopt::Usage ); 
with qw( IO::Reader IO::Writer ); 
with qw( VASP::POTCAR::Reader ); 

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

has 'element', ( 
    is        => 'ro', 
    isa       => Str,  
    predicate => '_has_element', 
    
    documentation => 'Comma separated list of elements'
); 

has '+input', ( 
    init_arg  => undef, 
    default   => 'POTCAR'
); 

has '+output', ( 
    init_arg  => undef, 
    default   => 'POTCAR'
); 

has '+o_mode', ( 
    default   => 'a'
); 

has 'pot_dir', ( 
    is        => 'ro', 
    isa       => Str, 
    init_arg  => undef, 
    default   => $ENV{ POT_DIR }, 
); 

has 'element_list', ( 
    is        => 'ro', 
    isa       => ArrayRef[ Element ],   
    traits    => [ qw( Array ) ], 
    init_arg  => undef,
    lazy      => 1, 
    default   => sub ( $self ) {
        return             
            $self->_has_element 
            ? [ split( /,/, $self->element ) ] 
            :[] 
    },    
    handles   => { 
        _add_element => 'push', 
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
sub getopt_usage_config {
    return 
        format   => "Usage: %c <make|append|info> [OPTIONS]", 
        headings => 1
}

sub info ( $self, $verbose = 1 ) { 
    # cache POTCAR
    -f $self->input ? $self->cache : return; 

    # list of xc
    my @xcs = $self->_list_cached; 

    # print pp  
    for my $xc ( @xcs ) {
        printf "\n=> Pseudopotential: %s\n", $xc if $verbose;  

        for my $pseudo ( $self->_get_cached( $xc )->@* ) {
            $self->_add_element( to_Element( $pseudo->[0] ) );  
            printf "%-10s %-6s %-10s %-s\n", @$pseudo if $verbose;  
        } 
    }

    # sanity check
    @xcs > 1 
    ? die "\n=> Error: Mixing different exchanges in POTCAR\n" 
    : $self->_set_xc( shift @xcs ); 
} 

sub make ( $self ) { 
    # delete existed POTCAR 
    $self->delete; 

    $self->append( $self->get_elements ); 
    $self->info; 
} 

sub append ( $self, @elements ) { 
    for ( grep is_Element( $_ ), @elements ) {  
        $self->_select( $_ ); 
        $self->_print( $self->_get_potcar( $_) ); 
    } 

    $self->refresh; 
} 

sub refresh ( $self ) { 
    $self->_clear_reader; 
    $self->_clear_writer; 
    $self->_clear_cache; 
} 

sub delete ( $self ) { 
    unlink $self->input; 
} 

sub _select ( $self, $element ) { 
    my @configs = $self->_list_potcar_configs( $element );  
    
    # populate potcar HashRef
    $self->_set_potcar( 
        $element => IO::KISS->new( 
            file   => $self->_select_potcar_config( @configs ),  
            mode   => 'r', 
            _chomp => 1 
        )->slurp 
    ); 
} 

sub _list_potcar_configs ( $self, $element ) { 
    return 
        map basename( $_ ), 
        grep /\/($element)(\z|\d|_|\.)/, 
        glob "${ \$self->pot_dir }/${ \$self->xc }/*"; 
} 

sub _select_potcar_config ( $self, @configs ) {  
    while ( 1 ) { 
        # prompt 
        printf "=> Pseudopotentials < %s >: ", join(' | ', @configs );  
        chomp ( my $choice = <STDIN> =~ s/\s+//rg ); 
        
        if ( grep $choice eq $_ , @configs ) { 
            return catfile( $self->pot_dir, $self->xc, $choice, 'POTCAR' ) 
        }
    }
} 

__PACKAGE__->meta->make_immutable;

1
