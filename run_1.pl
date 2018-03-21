#!/usr/bin/env perl 

#PBS -l nodes=::ppn=
#PBS -N 
#PBS -q 
#PBS -e ./std.err
#PBS -o ./std.out

use strict; 
use warnings; 
use autodie; 
use experimental 'signatures'; 

use Try::Tiny; 

use File::Path 'make_path'; 
use File::Copy 'copy'; 
use File::Basename 'basename'; 
use File::Spec::Functions 'catfile'; 

use IO::KISS; 
use VASP::INCAR; 
use VASP::KPOINTS;  

# params 
my $root_dir =  $ENV{PBS_O_WORKDIR}; 
my $bin_dir  = "$ENV{HOME}/DFT/bin"; 
my $job_id   = $1 if $ENV{PBS_JOBID} =~ /^(\d+)/;

# bash: cd $PBS_O_WORKDIR
chdir $root_dir; 

# bash: NPROCS=`wc -l < $PBS_NODEFILE`
my $nprocs = get_nprocs(); 

# vasp
my $version = '5.4.4'; 
my @inputs  = qw( INCAR KPOINTS POSCAR POTCAR ); 
my $vasp    = which_vasp_binary(); 

# one-shot
if ( has_input() ) { mpirun( $vasp ) } 

# read PBS_NODEFILE
sub get_nprocs { 
    my @nprocs  = IO::KISS->new( $ENV{ PBS_NODEFILE }, 'r' )->get_lines;  

    return scalar( @nprocs )
}

# check INCAR, POSCAR, KPOINTS, POTCAR
sub has_input { 
    return ( grep -e $_, @inputs ) == 4 ? 1 : 0
} 

# gamma, complex or ncl ? 
sub which_vasp_binary { 
    my $incar   = VASP::INCAR->new;  
    my $kpoints = VASP::KPOINTS->new;  

    return ( 
        $incar->get_lsorbit     ? "vasp.$version.ncl.x"   :
        $kpoints->get_nkpt == 1 ? "vasp.$version.gamma.x" : 
                                  "vasp.$version.x"
    )
}

# bash: mpirun -np $NPROCS ...
sub mpirun { 
    my $bin = shift; 

    system 'mpirun', '-np', $nprocs, $bin
} 
