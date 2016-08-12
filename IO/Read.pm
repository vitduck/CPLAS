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
sub read_file ( $self, $file ) { 
    open my $fh, '<', $file;  
    chomp (my @lines = <$fh>);  
    close $fh; 

    return \@lines; 
} 

sub slurp_file ( $self, $file ) { 
    open my $fh, '<', $file; 
    my $line = do { local $/ = undef; <$fh> };  
    close $fh; 

    return $line; 
} 

sub paragraph_file ( $self, $file ) {  
    open my $fh, '<', $file; 
    chomp (my @paragraphs = do { local $/ = ''; <$fh> });  
    close $fh; 

    return \@paragraphs; 
}

1; 
