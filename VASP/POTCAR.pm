package VASP::POTCAR; 

# core 
use File::Basename; 
use File::Spec::Functions; 

# cpan
use Moose;  
use MooseX::Types::Moose qw/ArrayRef HashRef Str/;  
use namespace::autoclean; 

# pragma
use autodie; 
use warnings FATAL => 'all'; 
use experimental qw/signatures/; 

# Moose class 
use IO::KISS;  

# Moose type 
use VASP::Periodic qw/Element/; 
use VASP::Exchange qw/VASP/; 

# Moose roles 
with qw/VASP::Parser/; 

# Moose attributes 
has 'pot_dir', ( 
    is        => 'ro', 
    isa       => Str, 
    init_arg  => undef, 
    default   => $ENV{POT_DIR} 
); 

has 'exchange', ( 
    is        => 'ro', 
    isa       => VASP, 
    required  => 1, 
); 

has 'elements', ( 
    is        => 'ro', 
    isa       => ArrayRef[Element], 
    traits    => ['Array'], 
    required  => 1, 
    handles   => { 
        list_elements => 'elements', 
    }, 
); 

has 'available_potcars', ( 
    is        => 'ro', 
    isa       => HashRef, 
    traits    => ['Hash'], 
    init_arg  => undef, 
    default   => sub ( $self ) { {} },  
    handles   => { 
        set_available_potcars  => 'set',  
        list_available_potcars => 'get',  
    }
); 

has 'selected_potcars', ( 
    is        => 'ro', 
    isa       => HashRef, 
    traits    => ['Hash'], 
    init_arg  => undef, 
    default   => sub ( $self ) { {} },  
    handles   => { 
        set_selected_potcars => 'set',  
        get_selected_potcars => 'get', 
    }
); 

# Moose private method 
sub _construct_available_potcars( $self, $element ) { 
    $self->set_available_potcars( 
        $element => [ 
            map basename($_), 
            grep /\/($element)(\z|\d|_|\.)/, 
            glob "${\$self->pot_dir}/${\$self->exchange}/*" 
        ]  
    );  
} 

sub _construct_selected_potcars( $self, $element ) { 
    my @potcars = $self->list_available_potcars($element)->@*; 
    
    # prompt 
    printf 
        "\n=> Pseudopotentials for %s: =| %s |=\n", 
        $element, join(' | ', @potcars );  

    # construct full path to file
    while ( 1 ) { 
        print "=> Choice: "; 
        chomp ( my $choice = <STDIN> =~ s/\s+//rg ); 
        if ( grep $choice eq $_ , @potcars ) {  
            $self->set_selected_potcars(
                $element => catfile($self->pot_dir, $self->exchange, $choice, 'POTCAR') 
            );  
            last; 
        }
    } 
} 

# Moose method 
sub make_potcar ( $self ) { 
    my $POTCAR = IO::KISS->new('POTCAR', 'w');      

    for my $element ( $self->list_elements ) { 
        $POTCAR->print(
            IO::KISS->new($self->get_selected_potcars($element), 'r')->slurp 
        )
    }
} 

sub BUILD ( $self, @args ) { 
    # check if potential directory is accessible 
    if ( not -d $self->pot_dir  ) { 
        die "Please export location of POTCAR files in .bashrc\n
        For example: export POT_DIR=/opt/VASP/POTCAR\n";
    }
    
    # after element is added, simultaneously 
    # set two attributes available_potcars and selected_potcars 
    for my $element ( $self->list_elements ) { 
        $self->_construct_available_potcars($element); 
        $self->_construct_selected_potcars($element); 
    } 

} 

# speed-up object construction 
__PACKAGE__->meta->make_immutable;

1; 
