package Gradient; 

use strict; 
use warnings; 
use experimental 'signatures'; 

use PDL; 
use PDL::Stats::Basic; 
use PDL::Graphics::Gnuplot; 

use IO::KISS;  
use Plot; 

our @ISA    = 'Exporter'; 
our @EXPORT = qw( 
    read_report 
    get_gradient
); 

sub read_report ( $cc, $z_12, $lpGkT ) { 
    my ( @cc, @z_12, @lpGkT );  

    my $report = IO::KISS->new( 'REPORT', 'r' ); 

    while ( local $_ = $report->get_line ) { 
        # constraint 
        if ( /cc>/  ) { 
            push @cc, ( split )[2] 
        } 

        # blue moon
        if ( /b_m>/ ) {  
            my @bm = split; 
            push @z_12,  $bm[ 2]; 
            push @lpGkT, $bm[-1]; 
        }
    } 

    $report->close; 

    # deref the piddle
    $$cc    = PDL->new( @cc    ); 
    $$z_12  = PDL->new( @z_12  ); 
    $$lpGkT = PDL->new( @lpGkT ); 
}

sub get_gradient ( $z_12, $lpGkT, $gradient ) { 
    $$gradient = $$lpGkT / $$z_12; 
} 

# # this number is from block_averaging
# sub get_agrad ( $bm, $agrad, $nblock = 75 ) { 
    # my ( @time, @grad ); 
    
    # for ( 0 .. $$bm->getdim(0) - 1 ) { 
        # if ( ( $_ +  1 ) % $nblock == 0 ) { 
            # my $z_12  = $$bm->slice( "0:$_, (0)" );  
            # my $lpGkT = $$bm->slice( "0:$_, (1)" );  
            
            # push @time, $_; 
            # push @grad, $lpGkT->average / $z_12->average; 
        # } 
    # } 

    # $$agrad = cat( 
        # PDL->new( @time ), 
        # PDL->new( @grad ) 
    # ); 
# } 

# sub get_mgrad ( $cc, $bm, $start = 0 ) { 
    # my $z_12  = $$bm->slice( "$start:-1, (0)" );  
    # my $lpGkT = $$bm->slice( "$start:-1, (1)" );  
    
    # # flatten piddle 
    # my $mean_lpGkT = Number::WithError->new( block_average( $lpGkT->list ) ); 
    # my $mean_z_12  = Number::WithError->new( block_average( $z_12->list  ) ); 
    
    # my $mean_grad  = $mean_lpGkT / $mean_z_12; 
    
    # #printf "=> <dF/dl>: %s\n", $mean_grad
    # printf "%7.3f %-s\n", $$cc->index(0) , $mean_grad
# } 

# sub write_grad ( $grad, $file ) {
    # my $io = IO::KISS->new( $file, 'w' ); 

    # for ( 0..$$grad->getdim(0) - 1 ) { 
        # $io->printf( 
            # "%d\t%7.3e\n", 
            # $$grad->at( $_, 0 ) + 1, 
            # $$grad->at( $_, 1 )
        # )
    # }

    # $io->close; 
# }

# sub plot_grad ( $cc, $x1y1, $x2y2 ) { 
    # my $figure = gpwin( 'x11', persist => 1, raise => 1 ); 
   
    # $figure->plot( 
        # # plot options
        # { 
            # title  => sprintf( "d-%s", $$cc->uniq ),  
            # xlabel => 'NSTEP', 
            # ylabel => 'eV',
            # grid   => 1
        # }, 

        # # curve options 
        # ( 
            # with      => 'lines', 
            # linecolor => [ rgb => $color{ red } ], 
            # linewidth => 2, 
            # legend    => 'dA/ds'
        # ), $$x1y1->slice( ":, (0)" ), $$x1y1->slice( ":, (1)" ), 
        
        # ( 
            # with      => 'lines', 
            # linecolor => [ rgb => $color{ blue } ], 
            # linewidth => 2, 
            # legend    => '<dA/ds>' 
        # ), $$x2y2->slice( ":, (0)" ), $$x2y2->slice( ":, (1)" ), 
    # )
# }

# sub block_average ( $gradient, $output ) { 
    # my $io = IO::KISS->new( $output, 'w' ); 
    
    # my $min_block_size = 1; 
    # my $max_block_size = $$gradient->nelem/4; 

    # for my $block_size ( $min_block_size .. $max_block_size ) { 
        # # array to hold averages of blocks
        # my @avg; 
        
        # # use a copy of original array
        # my @data = $$gradient->list; 

        # # split data into blocks with corresponding $block_size
        # while ( my @sub_block = splice @data, 0, $block_size ) { 
            # push @avg, PDL->new( @sub_block )->average; 
        # }

        # # statistics of averages of blocks 
        # my $avg = PDL->new( @avg ); 

        # $io->printf(
            # "%d\t%7.3f\t%7.3f\t%7.3f\n", 
            # $block_size, 
            # $avg->average, 
            # $avg->stdv, 
            # $avg->se
        # )
    # }

    # $io->close; 
# }

# # # simple block averaging
# # sub block_average ( @block ) { 
    # # my @avg; 
    # # my $nblock = 75; 
    
    # # while ( my @sub_block = splice @block, 0, $nblock ) { 
        # # my $sb = PDL->new( @sub_block ); 

        # # # average of sub block 
        # # push @avg, $sb->average; 
    # # }

    # # my $avg = PDL->new( @avg ); 
    
    # # # debug 
    # # # printf "Debug: %f\t%f\n", $avg->average, $avg->se; 
    
    # # #return ( $avg->average, $avg->stdv ) 
    # # return ( $avg->average, $avg->stdv ) 
# # }

# 1
