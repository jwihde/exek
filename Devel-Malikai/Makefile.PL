use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Devel::Malikai',
    AUTHOR              => q{Malikai <malikai@art1st>},
    VERSION_FROM        => 'lib/Devel/Malikai.pm',
    ABSTRACT_FROM       => 'lib/Devel/Malikai.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Devel-Malikai-*' },
);
