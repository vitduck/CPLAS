package VASP::KPOINTS; 

use strict; 
use warnings FATAL => 'all'; 
use feature 'switch','signatures';  
use namespace::autoclean; 

use List::Util 'product';  
use Moose;  
use MooseX::Types::Moose 'Str','Int','ArrayRef';  
use IO::KISS; 

no warnings 'experimental'; 

with 'IO::Reader';  

has 'file', ( 
    is       => 'ro', 
    isa      => Str,  
    lazy     => 1, 
    init_arg => undef, 
    default  => 'KPOINTS' 
); 

has 'comment', ( 
    is        => 'ro', 
    isa       => Str, 
    lazy      => 1, 
    init_arg  => undef, 
    builder   => '_build_comment' 
); 

has 'mode', ( 
    is        => 'ro', 
    isa       => Int,  
    lazy      => 1, 
    init_arg  => undef, 
    builder   => '_build_mode' 
);  

has 'scheme', ( 
    is        => 'ro', 
    isa       => Str,  
    lazy      => 1, 
    init_arg  => undef, 
    builder   => '_build_scheme' 
); 

has 'grid', ( 
    is       => 'ro', 
    isa      => ArrayRef, 
    traits   => [ 'Array' ], 
    lazy     => 1, 
    builder  => '_build_grid', 
    handles  => { get_grids => 'elements' } 
); 

has 'shift', ( 
    is       => 'ro', 
    isa      => ArrayRef, 
    traits   => [ 'Array' ], 
    lazy     => 1, 
    builder  => '_build_shift', 
    handles  => { get_shifts => 'elements' } 
); 

has 'nkpt', ( 
    is       => 'ro', 
    isa      => Int, 
    lazy     => 1, 
    init_arg => undef, 
    builder  => '_build_nkpt', 
); 

sub BUILD ( $self, @ ) { 
    $self->reader;  
} 

# cached KPOINTS 
sub _build_comment ( $self ) { return $self->read('comment') } 
sub _build_mode    ( $self ) { return $self->read('mode' ) }  
sub _build_scheme  ( $self ) { return $self->read('scheme') }
sub _build_grid    ( $self ) { return $self->read('grid') }   
sub _build_shift   ( $self ) { return $self->read('shift') }

sub _build_nkpt ( $self ) { 
    return (
        $self->mode == 0 ? 
        product($self->get_grids) : 
        $self->mode 
    )
}

sub _parse_file ( $self ) { 
    my %kp = ();  
   
    $kp{comment} =   $self->get_line; 
    $kp{mode}    =   $self->get_line;  
    $kp{scheme}  = ( $self->get_line ) =~ /^M/ ? 'Monkhorst-Pack' : 'Gamma-centered';
    
    given ( $kp{mode } ) {   
        when ( 0 )      { $kp{grid} = [ map int, map split, $self->get_line ] }
        when ( $_ > 0 ) { 
            while ( local $_ = $self->get_line ) {
                push $kp{grid}->@*, [ (split)[0,1,2] ]; 
            }
        }
        default { 
        ...
        } 
    }
    
    $kp{shift} = [ map split, $self->get_line ] if $kp{mode} == 0; 

    return \%kp 
} 

__PACKAGE__->meta->make_immutable;

1 
