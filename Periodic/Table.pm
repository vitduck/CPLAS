package Periodic::Table;  

use strict; 
use warnings; 
use MooseX::Types::Moose qw( Str Int ); 
use MooseX::Types -declare => [ qw( Element Element_Name Atomic_Number ) ]; 

use namespace::autoclean; 

my %table = (
      1 => [ 'H',      'Hydrogen', '0.32', '1.00'],
      2 => ['He',        'Helium', '0.31', '1.40'],
      3 => ['Li',       'Lithium', '1.63', '0.00'],
      4 => ['Be',     'Beryllium', '0.90', '0.00'],
      5 => [ 'B',         'Boron', '0.82', '0.00'],
      6 => [ 'C',        'Carbon', '0.77', '1.70'],
      7 => [ 'N',      'Nitrogen', '0.75', '1.50'],
      8 => [ 'O',        'Oxygen', '0.73', '1.40'], 
      9 => [ 'F',      'Fluorine', '0.72', '1.40'],
     10 => ['Ne',          'Neon', '0.71', '1.50'],
     11 => ['Na',        'Sodium', '1.54', '0.00'],
     12 => ['Mg',     'Magnesium', '1.36', '0.00'],
     13 => ['Al',     'Aluminium', '1.18', '0.00'],
     14 => ['Si',       'Silicon', '1.11', '0.00'],
     15 => [ 'P',    'Phosphorus', '1.06', '0.00'],
     16 => [ 'S',        'Sulfur', '1.02', '1.80'],
     17 => ['Cl',      'Chlorine', '0.99', '1.80'],
     18 => ['Ar',         'Argon', '0.98', '1.80'],
     19 => [ 'K',     'Potassium', '2.03', '0.00'],
     20 => ['Ca',       'Calcium', '1.74', '0.00'],
     21 => ['Sc',      'Scandium', '1.44', '0.00'],
     22 => ['Ti',      'Titanium', '1.32', '0.00'],
     23 => [ 'V',      'Vanadium', '1.22', '0.00'],
     24 => ['Cr',      'Chromium', '1.18', '0.00'],
     25 => ['Mn',     'Manganese', '1.17', '0.00'],
     26 => ['Fe',          'Iron', '1.17', '0.00'],
     27 => ['Co',        'Cobalt', '1.16', '0.00'],
     28 => ['Ni',        'Nickel', '1.15', '0.00'],
     29 => ['Cu',        'Copper', '1.17', '0.00'],
     30 => ['Zn',          'Zinc', '1.25', '0.00'],
     31 => ['Ga',       'Gallium', '1.26', '0.00'],
     32 => ['Ge',     'Germanium', '1.22', '0.00'],
     33 => ['As',       'Arsenic', '1.20', '0.00'],
     34 => ['Se',      'Selenium', '1.16', '2.00'],
     35 => ['Br',       'Bromine', '1.14', '2.00'],
     36 => ['Kr',       'Krypton', '1.12', '0.00'],
     37 => ['Rb',      'Rubidium', '2.16', '0.00'],
     38 => ['Sr',     'Strontium', '1.91', '2.20'],
     39 => [ 'Y',       'Yttrium', '1.62', '0.00'],
     40 => ['Zr',     'Zirconium', '1.45', '0.00'],
     41 => ['Nb',       'Niobium', '1.34', '0.00'],
     42 => ['Mo',    'Molybdenum', '1.30', '0.00'],
     43 => ['Tc',    'Technetium', '1.27', '0.00'],
     44 => ['Ru',     'Ruthenium', '1.25', '0.00'],
     45 => ['Rh',       'Rhodium', '1.25', '0.00'],
     46 => ['Pd',     'Palladium', '1.28', '0.00'],
     47 => ['Ag',        'Silver', '1.34', '0.00'],
     48 => ['Cd',       'Cadmium', '1.48', '0.00'],
     49 => ['In',        'Indium', '1.44', '0.00'],
     50 => ['Sn',           'Tin', '1.41', '0.00'],
     51 => ['Sb',      'Antimony', '1.40', '0.00'],
     52 => ['Te',     'Tellurium', '1.36', '0.00'],
     53 => [ 'I',        'Iodine', '1.33', '2.20'],
     54 => ['Xe',         'Xenon', '1.31', '0.00'],
     55 => ['Cs',        'Cesium', '2.35', '0.00'],
     56 => ['Ba',        'Barium', '1.98', '0.00'],
     57 => ['La',     'Lanthanum', '1.69', '0.00'],
     58 => ['Ce',        'Cerium', '1.65', '0.00'],
     59 => ['Pr',  'Praseodymium', '1.65', '0.00'],
     60 => ['Nd',     'Neodymium', '1.84', '0.00'],
     61 => ['Pm',    'Promethium', '1.63', '0.00'],
     62 => ['Sm',      'Samarium', '1.62', '0.00'],
     63 => ['Eu',      'Europium', '1.85', '0.00'],
     64 => ['Gd',    'Gadolinium', '1.61', '0.00'],
     65 => ['Tb',       'Terbium', '1.59', '0.00'],
     66 => ['Dy',    'Dysprosium', '1.59', '0.00'],
     67 => ['Ho',       'Holmium', '1.58', '0.00'],
     68 => ['Er',        'Erbium', '1.57', '0.00'],
     69 => ['Tm',       'Thulium', '1.56', '0.00'],
     70 => ['Yb',     'Ytterbium', '2.00', '0.00'],
     71 => ['Lu',      'Lutetium', '1.56', '0.00'],
     72 => ['Hf',       'Hafnium', '1.44', '0.00'],
     73 => ['Ta',      'Tantalum', '1.34', '0.00'],
     74 => [ 'W',      'Tungsten', '1.30', '0.00'],
     75 => ['Re',       'Rhenium', '1.28', '0.00'],
     76 => ['Os',        'Osmium', '1.26', '0.00'],
     77 => ['Ir',       'Iridium', '1.27', '0.00'],
     78 => ['Pt',      'Platinum', '1.30', '0.00'],
     79 => ['Au',          'Gold', '1.34', '0.00'],
     80 => ['Hg',       'Mercury', '1.49', '0.00'],
     81 => ['Tl',      'Thallium', '1.48', '0.00'],
     82 => ['Pb',          'Lead', '1.47', '0.00'],
     83 => ['Bi',       'Bismuth', '1.46', '0.00'],
     84 => ['Po',      'Polonium', '1.46', '0.00'],
     85 => ['At',      'Astatine', '2.00', '0.00'],
     86 => ['Rn',         'Radon', '2.00', '0.00'],
     87 => ['Fr',      'Francium', '2.00', '0.00'],
     88 => ['Ra',        'Radium', '2.00', '0.00'],
     89 => ['Ac',      'Actinium', '2.00', '0.00'],
     90 => ['Th',       'Thorium', '1.65', '0.00'],
     91 => ['Pa',  'Protactinium', '2.00', '0.00'],
     92 => [ 'U',       'Uranium', '1.42', '0.00'],
     93 => ['Np',     'Neptunium', '2.00', '0.00'],
     94 => ['Pu',     'Plutonium', '2.00', '0.00'],
     95 => ['Am',     'Americium', '2.00', '0.00'],
     96 => ['Cm',        'Curium', '2.00', '0.00'],
     97 => ['Bk',     'Berkelium', '2.00', '0.00'],
     98 => ['Cf',   'Californium', '2.00', '0.00'],
     99 => ['Es',   'Einsteinium', '2.00', '0.00'],
    100 => ['Fm',       'Fermium', '2.00', '0.00'],
    101 => ['Md',   'Mendelevium', '2.00', '0.00'],
    102 => ['No',      'Nobelium', '2.00', '0.00'],
    103 => ['Lr',    'Lawrencium', '2.00', '0.00'],
    104 => ['Rf', 'Rutherfordium', '2.00', '0.00'],
    105 => ['Db',       'Dubnium', '2.00', '0.00'],
    106 => ['Sg',    'Seaborgium', '2.00', '0.00'],
    107 => ['Bh',       'Bohrium', '2.00', '0.00'],
    108 => ['Hs',       'Hassium', '2.00', '0.00'],
    109 => ['Mt',    'Meitnerium', '2.00', '0.00'],
    110 => ['Ds',  'Darmstadtium', '2.00', '0.00'],
    111 => ['Rg',   'Roentgenium', '2.00', '0.00'],
    112 => ['Cp',   'Copernicium', '2.00', '0.00'],
); 

subtype Element, as Str, where { 
    my $element = $_;  
    return grep $element eq $_->[0], values %table; 
}; 

subtype Element_Name, as Str, where { 
    my $name = $_; 
    return grep $name eq $_->[1], values %table; 
}; 

subtype Atomic_Number, as Int, where { 
    return exists $table{$_}
}; 

coerce Element, from Atomic_Number, via { 
    return $table{$_}->[0]; 
};  

coerce Atomic_Number, from Element, via { 
    my $element = $_;  
    return ( grep $element eq $table{$_}[0], keys %table )[0]  
};  

coerce Element_Name, from Element, via { 
    return $table{to_Atomic_Number( $_ )}[1]; 
};  

1
