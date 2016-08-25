package VASP::POTCAR; 

# core 
use File::Basename; 
use File::Spec::Functions; 

# cpan
use Moose;  
use MooseX::Types; 
use namespace::autoclean; 

# pragma
use autodie; 
use warnings FATAL => 'all'; 
use experimental qw/signatures/; 

# Moose class 
use IO::KISS;  

# Moose roles 
with 'VASP::Parser', 'VASP::Periodic';  

# Moose attributes 
has 'dir', ( 
    is        => 'ro', 
    isa       => 'Str', 
    init_arg  => 1, 

    default   => sub ( $self ) {  
        return $ENV{POTCAR};  
    } 
); 

has 'exchange', ( 
    is        => 'ro', 
    isa       => enum([ qw/PAW_PBE PAW_GGA PAW_LDA POT_GGA POT_LDA/ ]), 
    default   => 'PAW_PBE',  
); 

has 'element', ( 
    is        => 'ro', 
    isa       => 'Str', 
    required  => 1,   
); 

has 'potcars', ( 
    is       => 'ro', 
    isa      => 'ArrayRef[Str]',  
    init_arg => undef, 
    lazy     => 1, 

    default  => sub ( $self ) { 
        my $dir      = $self->dir; 
        my $exchange = $self->exchange; 
        my $element  = $self->element; 

        return [ 
            map { basename $_ } grep /\/($element)(\z|\d|_|\.)/, <$dir/$exchange/*>     
        ]
    }, 
); 

# from VASP::Parser
# make it lazy ( blame the hash ) 
has '+file', ( 
    lazy      => 1, 

    default   => sub ( $self ) { 
        my $element = $self->element; 
        my $name    = $self->element_name($element); 

        printf "\n=> Pseudopotentials for %s: =| %s |=\n", $name, join(' | ', $self->potcars->@*);

        # Promp user to choose potential 
        while ( 1 ) { 
            print "=> Choice: "; 

            # remove newline, spaces, etc
            chomp ( my $choice = <STDIN> ); 
            $choice =~ s/\s+//g; 

            if ( grep { $choice eq $_ } $self->potcars->@* ) {  
                return catfile($self->dir, $self->exchange, $choice, 'POTCAR') 
            }
        }
    } 
); 

has 'history', ( 
    is       => 'ro', 
    isa      => 'HashRef[Str]',  
    traits   => ['Hash'], 
    init_arg => undef, 
    lazy     => 1, 

    default  => sub ( $self ) { 
        my $info = {}; 

        for ( $self->content->@* ) { 
            if ( /VRHFIN =(\w+)\s*:(.*)/ ) { 
                # valence shell 
                if ( my @valence = ( $2 =~ /([spdf]\d+)/g ) ) {  
                    $info->{shell} = join '', @valence;               
                } else { 
                    $info->{shell} = (split ' ', $2)[0];  
                }
            }

            if ( /TITEL/ ) { 
                $info->@{qw/config date/} = ( split )[3,4]; 
                $info->{date} //= '...'; 
            }
        } 
            
        return $info;  
    },  

    # delegations 
    handles => { 
        map { $_ => [ get => $_ ] } qw/config shell date/  
    }, 
);  

# Moose sub 
sub make_potcar ( $self ) { 
    # append mode 
    my $io = IO::KISS->new('POTCAR', 'a');     

    for ( $self->content->@* ) { 
        $io->print($_); 
    } 
} 

sub BUILD ( $self, @args ) { 
    # check if potential directory is accessible 
    if ( not -d $self->dir  ) { 
        die "Please export location of POTCAR files in .bashrc\n
        For example: export POTCAR=/opt/VASP/POTCAR\n";
    }
} 

# speed-up object construction 
__PACKAGE__->meta->make_immutable;

1; 
