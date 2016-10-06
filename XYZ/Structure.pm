package XYZ::Structure; 

use Moose; 
use MooseX::Types::Moose qw( Str Int ); 
use namespace::autoclean; 
use experimental qw( signatures ); 

with qw( IO::Reader ); 
with qw( XYZ::Geometry );   
with qw( XYZ::Xmakemol ); 
with qw( XYZ::Reader ); 

has '+input', ( 
    required  => 1, 
); 

sub BUILD ( $self, @ ) { 
    $self->cache if -f $self->input
}

1
