package XYZ::Xmakemol; 

# cpan 
use Moose::Role; 
use namespace::autoclean; 

# pragma 
use autodie; 
use warnings FATAL => 'all'; 
use experimental qw( signatures );

sub xmakemol ( $self, $xyz ) { 
    print "=> xmakemol $xyz ...\n"; 
    my $bgcolor = $ENV{XMAKEMOL_BG} || '#D3D3D3'; 
    system "xmakemol -c '$bgcolor' -f $xyz >/dev/null 2>&1 &"; 
} 

1; 
