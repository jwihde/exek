use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Finance::Exek',
    AUTHOR              => q{Jason Ihde <jihde@exek.net>},
    VERSION_FROM        => 'lib/Finance/Exek.pm',
    ABSTRACT_FROM       => 'lib/Finance/Exek.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Finance-Exek-*' },
);
