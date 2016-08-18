package IO::KISS; 

# pragma
use autodie; 
use warnings FATAL => 'all'; 

# cpan
use Moose; 
use namespace::autoclean; 

# features
use experimental qw/signatures/; 

# Moose attributes 
has 'input', ( 
    is       => 'ro', 
    isa      => 'Str', 
    required => 1, 
); 

has 'filehandle', ( 
    is       => 'ro', 
    lazy     => 1, 
    init_arg => undef, 

    default  => sub ( $self ) { 
        # open fh to either a file or a string
        open my $fh, '<', 
        ( -f $self->input ? $self->input : \$self->input ); 

        return $fh; 
    }, 
); 

# slurp mode 
has 'string', ( 
    is       => 'ro', 
    isa      => 'Str', 
    lazy     => 1, 
    init_arg => undef, 
    reader   => 'slurp', 

    default  => sub ( $self ) { 
        my $fh = $self->filehandle; 
        chomp ( my $line = do { local $/ = undef; <$fh> } );

    return $line; 
    }, 
); 

# line mode 
has 'line', ( 
    is       => 'ro', 
    isa      => 'ArrayRef[Str]',  
    traits  => ['Array'],
    lazy     => 1, 
    init_arg => undef, 

    default  => sub ( $self ) { 
        my $fh   = $self->filehandle; 
        chomp ( my @lines = <$fh> ); 

        return \@lines; 
    },  
    
    handles => { 
        get_line  => 'shift', 
        get_lines => 'elements', 
    }, 
); 

# paragraph mode 
has 'paragraph', ( 
    is       => 'ro', 
    isa      => 'ArrayRef[Str]',  
    traits  => ['Array'],
    lazy     => 1, 
    init_arg => undef, 

    default  => sub ( $self ) { 
        my $fh   = $self->filehandle; 
        chomp (my @paragraphs = do { local $/ = ''; <$fh> });  

        return \@paragraphs;  
    },  

    handles => { 
        get_paragraph  => 'shift', 
        get_paragraphs => 'elements', 
    }, 
); 

# simple constructors 
override BUILDARGS => sub ( $class, @args ) { 
    return ( @args == 1 ? { input => $args[0] } : super ); 
}; 

# speed-up object construction 
__PACKAGE__->meta->make_immutable;

1; 
