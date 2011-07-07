#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Devel::Malikai' ) || print "Bail out!
";
}

diag( "Testing Devel::Malikai $Devel::Malikai::VERSION, Perl $], $^X" );
