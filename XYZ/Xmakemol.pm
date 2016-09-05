package XYZ::Xmakemol; 

use Moose::Role; 

use strictures 2; 
use namespace::autoclean; 
use experimental qw( signatures );

sub xmakemol ( $self, $xyz ) { 
    print "=> xmakemol $xyz ...\n"; 
    my $bgcolor = $ENV{XMAKEMOL_BG} || '#D3D3D3'; 
    system "xmakemol -c '$bgcolor' -f $xyz >/dev/null 2>&1 &"; 
} 

1; 
