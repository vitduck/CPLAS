package IO::Read; 

# pragma
use autodie; 
use warnings FATAL => 'all'; 

# cpan
use Moose::Role;  
use namespace::autoclean; 

# features
use experimental qw(signatures); 

# Moose methods 
sub fh ( $self, $input ) { 
    my $fh; 

    # Warning: 
    # Unsuccessful stat on filename containing newline
    chomp ( $input ); 
    
    if ( -f $input ) {  
        # fh to file 
        open $fh, '<', $input;  
    } else { 
        # fh to string 
        open $fh, '<', \$input;  
    } 

    return $fh; 
} 

sub readline ( $self, $input ) { 
    my $fh   = $self->fh($input); 
    chomp (my @lines = <$fh>);  
    close $fh; 

    return \@lines; 
} 

sub slurp ( $self, $input ) { 
    my $fh = $self->fh($input); 
    my $line = do { local $/ = undef; <$fh> };  
    close $fh; 

    return $line; 
} 

sub paragraph ( $self, $input ) {  
    my $fh = $self->fh($input); 
    chomp (my @paragraphs = do { local $/ = ''; <$fh> });  
    close $fh; 

    return \@paragraphs; 
}


1; 
