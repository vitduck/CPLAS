#!/usr/bin/env perl 

use strict; 
use warnings; 

use Data::Printer; 
use VASP::STOPCAR;  

use Carp 'verbose';
$SIG{ __DIE__ } = sub { Carp::confess( @_ ) };

my $STOPCAR = VASP::STOPCAR->new; 

$STOPCAR->stop; 
