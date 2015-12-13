package MD; 

use strict; 
use warnings; 

use Storable qw( store retrieve );  

use Math::Linalg qw( sum ); 
use Util qw( read_file ); 
use XYZ qw( set_pbc tag_xyz direct_to_cart ); 

our @profile     = qw( read_profile sort_profile merge_profile moving_average );  
our @trajectory  = qw( save_traj retrieve_traj merge_traj );  
our @util        = qw( is_valid_istep normalize print_trajectory );  

our @ISA         = qw( Exporter );  
our @EXPORT      = ();  
our @EXPORT_OK   = ( @profile, @trajectory, @util ); 
our %EXPORT_TAGS = (
    profile    => \@profile, 
    trajectory => \@trajectory, 
    util       => \@util, 
); 

#---------#
# PROFILE #
#---------#

# istep, T(K) and F(eV) from output of get_potential 
# args  
# -< profile.dat 
# -< ref of potential hash (istep => [T,F])
# return 
# -> null
sub read_profile { 
    my ( $file ) = @_;  

    my %profile = ();  

    for ( read_file($file) ) { 
        # skip comment and blank line 
        if ( /^#/ ) { next }  
        if ( /^\s*$/ ) { next } 

        # accumulated step, T, and F
        my ( $istep, $temp, $pot ) = ( split )[0,-2,-1]; 
        $profile{$istep} = [ $temp, $pot ]; 
    }

    printf "=> Retrieve potential profile from %s\n", $file; 
    printf "=> Hash contains %d entries\n\n", scalar(keys %profile); 

    return %profile;   
}

# sort the potential profile for local minimum and maximum 
# args 
# -< ref to potential hash (istep => [T,F])
# -< period of ionic steps for sorting  
# -< ref to array of local minima
# -< ref to array of local maxima
# return
# -> null
sub sort_profile { 
    my ( $md, $periodicity => $minima, $maxima, $pes ) = @_; 

    # enumerate ionic steps
    my @nsw = sort { $a <=> $b } keys %$md; 

    # split according to periodicity
    while ( my @pnsw = splice @nsw, 0, $periodicity ) { 
        my @sorted_md = ( sort { $md->{$a}[1] <=> $md->{$b}[1] } @pnsw )[0,-1];  

        push @$minima, $sorted_md[0];  
        push @$maxima, $sorted_md[1]; 
    }

    # sanity check 
    if ( @$minima != @$maxima ) { die "Something weired is going on\n" }

    # pes 
    @$pes = sort { $a <=> $b } ( @$minima, @$maxima ); 

    return; 
}

# merge md profile 
# args 
# -< array of profile files 
# -< merged profile 
# return 
# -> null
sub merge_profile { 
    my ( $profile => $output ) = @_; 

    open my $fh, '>', $output or die "Cannot write to $output\n"; 

    # header 
    print $fh "# global local T(K) Potental(eV)\n";

    my $count = 0; 
    for my $file ( @$profile ) { 
        printf $fh "# $file\n"; 
        
        my %profile = read_profile($file);     
        
        # re-write with accumulated ionic step 
        for my $istep ( sort { $a <=> $b } keys %profile ) { 
            printf $fh "%d\t%d\t%5d\t%10.5f\n", ++$count, $istep, @{$profile{$istep}};  
        }

        # record break 
        print $fh "\n\n" unless $file eq $profile->[-1];  
    }
    
    close $fh; 
    
    print "=> Merge profiles to '$output'\n"; 
    printf "=> Hash contains %d entries\n\n", $count; 

    return; 
}

# moving averages of potential profile 
# ref: http://mathworld.wolfram.com/MovingAverage.html
# args 
# -< ref to potential hash (istep => [T,F])
# -< period of ionic step to be averaged 
# -< output file 
# return 
# -> null
sub moving_average { 
    my ( $md, $period => $output ) = @_; 

    # extract array of potentials (last column)
    my @potentials = map { $md->{$_}[-1] } sort { $a <=> $b } keys %$md; 

    # total number of averages point
    my $naverage = scalar(@potentials) - $period + 1; 

    # calculating moving average 
    print "=> Short-time averages of potential energy over period of $period steps: $output\n"; 

    my $index = 0; 
    open my $fh, '>', $output or die "Cannot write to $output\n"; 

    for ( 1..$naverage ) { 
        my $average = (sum(@potentials[$index..($index+$period-1)]))/$period; 
        printf $fh "%d\t%10.5f\n", ++$index, $average; 
    }

    close $fh; 

    return; 
}

#------------#
# TRAJECTORY #
#------------#

# save trajectory to disk
# args  
# -< ref to trajectory (array of ref to 2d coordinate) 
# -< stored output
# return: 
# -> null
sub save_traj { 
    my ( $traj => $output ) = @_; 

    print  "=> Save trajectory as '$output'\n"; 
    printf "=> Hash contains %d entries\n", scalar(keys %$traj); 
    store $traj => $output;  

    return; 
}

# retrieve trajectory to disk
# args 
# -< stored data 
# return 
# -> traj hash 
sub retrieve_traj { 
    my ( $stored_traj ) = @_; 

    # trajectory is required 
    unless ( -e $stored_traj ) { die "$stored_traj does not exists\n" } 

    # retored traj as hash reference 
    my $traj = retrieve($stored_traj); 
    print  "=> Retrieve trajectory from '$stored_traj'\n"; 
    printf "=> Hash contains %d entries\n\n", scalar(keys %$traj); 

    return %$traj; 
}

# merge trajectory stored on disk 
# args
# -< array of stored trajectory 
# -< mergerd trajectory 
# return 
# -> null 
sub merge_traj { 
    my ( $trajectory => $output ) = @_; 

    my %merged_traj = ();  

    for my $file ( @$trajectory ) { 
        # inital hash size
        my $size = keys %merged_traj; 

        # shift hash keys
        my %traj = retrieve_traj($file); 
        my @keys = map { $_ + $size } keys %traj; 
        
        # merge hash 
        @merged_traj{@keys} = values %traj; 
    }

    # save merged trajectory 
    save_traj(\%merged_traj => $output); 

    return; 
}

#-------# 
# OTHER #
#-------# 
# sanity check against profile and trajectory hash 
# args 
# -< step 
# -< hash ref of profile 
# -< hash ref of trajectory 
# return 
# -> null
sub is_valid_istep {  
    my ( $istep, $profile, $traj ) = @_; 

    if ( ! exists $profile->{$istep} ) { die "=> #$istep does not exist in MD profile\n" } 
    if ( ! exists $traj->{$istep} )    { die "=> #$istep does not exist in MD trajectory\n" } 
    
    return; 
}

# normalize profile and trajectory 
# args 
# -< hash ref of profile 
# -< hash ref of trajectory 
# return 
# -> 0|1;  
sub normalize { 
    my ( $profile, $traj ) = @_; 

    # same size hash, no action required 
    if ( keys %$profile == keys %$traj ) { return 0 } 

    # hash comparison
    my ( $short, $long ) = 
    map { $_->[0] } 
    sort { @{$a->[1]} <=> @{$b->[1]} } 
    map { [ $_, [ keys %$_ ] ] } ( $profile, $traj ); 
    
    # hash element difference 
    my %diff; 
    @diff{keys %$long} = (); 
    delete @diff{keys %$short}; 

    # remove element from larger hash 
    delete @$long{keys %diff}; 

    # this is to updated trajectory hash 
    return ( $traj eq $long ? 1 : 0 );  
}

# print trajectory 
# args 
# -< 
# return 
# -> 
sub print_trajectory { 
    my ( $step, $profile, $traj, $ref, $dxyz, $nxyz => $output ) = @_; 

    my @tags = tag_xyz($ref->{atom}, $ref->{natom}, $nxyz); 

    open my $fh, '>', $output or die "Cannot write to $output\n"; 
    # comments
    for my $istep ( @$step ) { 
        my $comment = sprintf("#%d:  T= %.1f  F= %-10.5f", $istep, @{$profile->{$istep}});  
        direct_to_cart($ref->{cell}, $traj->{$istep}, $dxyz, $nxyz, \@tags, $comment => $fh); 
    }
    close $fh; 

    return; 
}

# last evaluated expression 
1;
