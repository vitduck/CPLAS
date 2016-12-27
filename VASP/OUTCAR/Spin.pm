package VASP::OUTCAR::Spin;  

use Moose::Role;  
use MooseX::Types::Moose 'RegexpRef'; 

use namespace::autoclean; 
use experimental 'signatures';  

with 'VASP::Spin';  

has '_magmom_regex', ( 
    is        => 'ro', 
    isa       => RegexpRef, 
    init_arg  => undef, 
    lazy      => 1, 
    default   => sub { 
        qr/
            (?:
                magnetization\ \(x\)\n
                .+?\n
                # of ion\s+s\s+p\s+d\s+tot\n
                -+\n
            )
            (.+?) 
            (?: 
                -+\n
            )
        /xs 
    } 
); 

sub _build_magmom ( $self ) {
    my $magmom = ( $self->slurped =~ /${ \$self->_magmom_regex }/g )[-1]; 

    my @magmom = (
        map { (split)[-1] } 
        IO::KISS->new( \ $magmom, 'r' )->get_lines 
    ); 
    
    # return indexed hash
    return { 
        map { $_ + 1 => $magmom[ $_ ] } 
        0..$#magmom 
    }
} 

1 
