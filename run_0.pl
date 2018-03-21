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
my $root_dir  =  $ENV{PBS_O_WORKDIR}; 
my $bin_dir   = "$ENV{HOME}/DFT/bin"; 
my $job_id    = $1 if $ENV{PBS_JOBID} =~ /^(\d+)/;
my $template  = "$ENV{HOME}/DFT/bootstrap"; 
my $bootstrap = ''; 

# bash: cd $PBS_O_WORKDIR
chdir $root_dir; 

# bash: NPROCS=`wc -l < $PBS_NODEFILE`
my $nprocs = get_nprocs(); 

# vasp 
my $version = '5.4.4'; 
my @inputs  = qw( INCAR KPOINTS POSCAR POTCAR ); 

# groundhog day
bootstrap(); 
iterator();  

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
    my $bin = shift ; 

    system 'mpirun', '-np', $nprocs, $bin
} 

# bash: mkdir $PBS_O_WORKDIR/bootstrap-$PBS_JOBID
sub bootstrap { 
    $bootstrap = "$root_dir/bootstrap-$job_id";

    # make bootstrap dir 
    make_path( $bootstrap ); 
    
    # copy VASP inputs to bootstrap dir
    for my $input ( @inputs ) {  
        copy "$template/$input" => $bootstrap 
    }
} 

# ad infinitum
sub iterator {   
    while ( 1 ) { 
        my @calc  = (); 
        my %tree  = ();     
        my @queue = ( [ $root_dir, \ %tree ] ); 

        while ( my $next = shift @queue ) { 
            my ( $path, $href ) = @$next; 
            my $basename = basename( $path ); 

            # update queue 
            $href->{ $basename } = get_subdir( $path, \ @queue );  

            # update @calc
            push @calc, $path if defined $href->{ $basename }; 

        }
        for ( @calc ) { 
            try { 
                chdir $_; 
                my $vasp = which_vasp_binary(); 

                if ( /bootstrap/ ) { 
                    mpirun( $vasp ); 
                }

                if ( ! -e 'OUTCAR' && has_input() ) {   
                    mpirun( $vasp ) 
                }
            };  
        }
    }
} 

# black magic
sub get_subdir ( $path, $queue ) { 
    return (
        -f $path ? undef : 
        -l $path ? undef : 
        do { 
            my $sub_ref = {}; 

            # breadth first 
            opendir my ( $dir_fh ), $path; 

            unshift $queue->@*,  
                map { [ $_, $sub_ref ] }     # sub_ref is {} 
                map { catfile( $path, $_ ) } # recover full path 
                sort { $a cmp $b }           # sorting
                grep { ! /^\.\.?$/ }         # skip "." and ".."
                readdir $dir_fh;

            closedir $dir_fh; 

            $sub_ref; 
        }
    )
}
