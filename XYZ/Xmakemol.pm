package XYZ::Xmakemol; 

use strict; 
use warnings FATAL => 'all'; 
use feature 'signatures'; 
use namespace::autoclean; 

use Moose::Role; 

no warnings 'experimental';

sub xmakemol ( $self, $xyz ) { 
    print "=> xmakemol $xyz ...\n"; 
    my $bgcolor = $ENV{XMAKEMOL_BG} || '#D3D3D3'; 
    system "xmakemol -c '$bgcolor' -f $xyz >/dev/null 2>&1 &"; 
} 

1; 
