package VASP::TBdyn::Thermo; 

use autodie; 
use strict; 
use warnings; 
use experimental 'signatures'; 

use PDL; 
use PDL::Graphics::Gnuplot; 

use IO::KISS; 

use VASP::TBdyn::Plot; 

our @ISA    = 'Exporter'; 
our @EXPORT = qw( 
    collect_data
    read_data
    print_thermo
    plot_thermo
); 

sub collect_data ( $input, $output ) { 
    my @thermo; 

    # read list of dirs from dir.in
    chomp ( my @dirs = IO::KISS->new( 'dir.in', 'r' )->get_lines  ); 
    
    # loop through the list of directories
    for ( @dirs ) {  
        chomp ( my @lines = IO::KISS->new( "$_/$input", 'r' )->get_lines );   

        # header; 
        my $constraint  = ( split ' ', shift @lines )[2]; 
        my $corr_length = ( split ' ', shift @lines )[3];  
        
        # nth line of blocked_*.dat
        push @thermo, [ $constraint, split ' ', $lines[ $corr_length -1 ] ];  
    }
    
    # open output: pmf.dat | dU.dat
    
    my $io = IO::KISS->new( $output , 'w' ); 
    $io->printf( "%7.3f %d %10.5f %10.5f %10.5f\n", @$_ ) for @thermo; 
    $io->close; 
    
    print "=> $output\n"; 
} 

sub read_data ( $input, $cc, $thermo, $variance ) { 
    my ( @cc, @thermos, @variances ); 

    for ( IO::KISS->new( $input, 'r' )->get_lines ) { 
        next if /#/; 

        my ( $cc, $corr_length, $thermo, $stdv, $se ) = split; 

        push @cc, $cc; 
        push @thermos, $thermo; 
        push @variances, $stdv**2; 
    } 

    # deref PDL piddle
    $$cc       = PDL->new( @cc ); 
    $$thermo   = PDL->new( @thermos ); 
    $$variance = PDL->new( @variances ); 
} 

sub print_thermo ( $cc, $thermo, $variance, $output ) { 
    my $io = IO::KISS->new( $output, 'w' ); 
    
    for ( 0..$$cc->nelem - 1 ) { 
        $io->printf( 
            "%7.3f  %10.5f  %10.5f\n", 
            $$cc->at( $_ ), 
            $$thermo->at( $_ ), 
            sqrt( $$variance->at( $_ ) )
        )
    }
    
    $io->close; 
    
    print "=> $output\n"; 
} 

sub plot_thermo ( $cc, $thermo, $variance, $title, $color ) { 
    my $zeroes = PDL->zeroes( $$cc->nelem );  

    my $figure = gpwin( 
        'x11', 
        persist  => 1, 
        raise    => 1, 
        enhanced => 1 
    ); 

    my ( $x_min, $x_max ) = ( $$cc->min, $$cc->max ); 
    my ( $y_min, $y_max ) = ( $$thermo->min, $$thermo->max ); 

    $figure->plot( 
        # plot options
        { 
            title  => $title, 
            xlabel => 'Reaction Coordinate (A)', 
            ylabel => 'Energy (eV)',
            xrange => [ $x_min - 0.05, $x_max + 0.05 ], 
            yrange => [ $y_min - 0.50, $y_max + 0.50 ], 
            grid   => 1,
        }, 

        # cubic spline
        ( 
            with      => 'lines', 
            linestyle => 1,
            linecolor => [ rgb => $hcolor{ $color } ], 
            linewidth => 3, 
            smooth    => 'cspline', 
        ), $$cc, $$thermo, 

        # free energy 
        ( 
            with      => 'yerrorbars',
            tuplesize => 3,
            linestyle => -1, 
            linewidth => 2,
            pointsize => 1,
            pointtype => 4,
            # legend    => '{/Symbol D}A', 
        ), $$cc, $$thermo, $$variance->sqrt, 

        ( 
            with      => 'lines', 
            linestyle => -1,
            linewidth =>  2, 
        ), $$cc, $zeroes  
    )
}

1; 
