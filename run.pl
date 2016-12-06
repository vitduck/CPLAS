#!/usr/bin/env perl 

#PBS -l nodes=8:SANDY:ppn=12
#PBS -N :)
#PBS -e ./std.err
#PBS -o ./std.out

use strict; 
use warnings; 
use autodie; 
use experimental qw/signatures/;  

use File::Path qw/make_path/;  
use File::Copy qw/copy/;  
use File::Basename qw/basename/;  
use File::Spec::Functions qw/catfile/;  

use Try::Tiny; 
use Data::Printer; 
use IO::KISS; 
use VASP::INCAR; 
use VASP::KPOINTS;  

#--------#
# params #
#--------#
my $version   = '5.4.1'; 
my $nprocs    = get_nprocs(); 
my $root_dir  =  $ENV{PBS_O_WORKDIR}; 
my $bin_dir   = "$ENV{HOME}/DFT/build"; 
my $template  = "$ENV{HOME}/DFT/bootstrap"; 
my $job_id    = $1 if $ENV{PBS_JOBID} =~ /^(\d+)/;
my $bootstrap = ''; 

my @inputs    = qw/INCAR KPOINTS POSCAR POTCAR/;  

#------# 
# main #
#------#
chdir $root_dir; 
check_input() ? execute_vasp() : iterator(); 

#-------------#
# subroutines #
#-------------#
sub bootstrap { 
    $bootstrap = "$root_dir/bootstrap-$job_id";

    make_path( $bootstrap ); 
    copy "$template/$_" => $bootstrap for @inputs;  
} 

sub iterator {   
    # bootstraping calculation
    bootstrap(); 
    
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
                execute_vasp() if /bootstrap/;  
                execute_vasp() unless -e 'OUTCAR' 
            };  
        }
    }
} 

sub check_input { 
    return ( grep -e $_, @inputs ) == 4 ? 1 : 0
} 

sub execute_vasp { 
    # short circuit
    return unless check_input();  

    # parse INCAR
    my $module = get_module(); 

    # parse KPOINTS 
    my $num_kp = get_nkpt(); 

    # choose correct binary
    my $vasp = 
        $num_kp == 1 
        ? "$bin_dir/vasp.$version.$module.gamma.x"  
        : "$bin_dir/vasp.$version.$module.x"; 

    # run vasp 
    system 'mpirun', '-np', $nprocs, $vasp 
} 

sub get_module { 
    my $incar  = VASP::INCAR->new;  
    
    return ( 
        $incar->get_mdalgo_tag ? 'tbdyn' : 
        $incar->get_neb_tag    ? 'neb'   : 
        'std' 
    )
}

sub get_nkpt { 
    return VASP::KPOINTS->new->get_nkpt;  
} 

sub get_nprocs { 
    my @nprocs  = IO::KISS->new( 
        file   => $ENV{ PBS_NODEFILE }, 
        mode   => 'r', 
        _chomp => 1
    )->get_lines;  

    return scalar( @nprocs )
}

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
