#!/usr/bin/env perl 

use strict; 
use warnings; 

use IO::KISS; 
use Data::Printer; 
use File::Copy; 

# frozen 
my @frozen = (); 
# my @frozen = qw( 
    # 8 
    # 12 14 17 19 
    # 22 23 24 25 27 
    # 30 31 32 33 
# ); 

# read xyz 
my @xyz = map [ (split)[1..3] ], IO::KISS->new (
    file   => 'geometry.xyz', 
    mode   => 'r', 
    _chomp => 1, 
)->get_lines;  

# indexing 
my %xyz = map { $_+1 => $xyz[$_] } 0..$#xyz; 

# copy file 
my $top = $0 =~ s/make\.pl/template/r;  

for ( qw( ICONST INCAR KPOINTS POSCAR POTCAR ) ) { 
    copy "$top/$_" => $_
} 

# append to POSCAR 
my $poscar = IO::KISS->new( 'POSCAR', 'a' ); 

for my $index ( sort { $a <=> $b } keys %xyz  ) {  
    ( grep $index eq $_, @frozen )
    ? $poscar->printf( "%7.3f\t%7.3f\t%7.3f  F  F  F\n", $xyz{$index}->@* )
    : $poscar->printf( "%7.3f\t%7.3f\t%7.3f  T  T  T\n", $xyz{$index}->@* )
} 

$poscar->close; 
