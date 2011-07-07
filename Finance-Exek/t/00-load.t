#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Finance::Exek' ) || print "Bail out!
";
}

diag( "Testing Finance::Exek $Finance::Exek::VERSION, Perl $], $^X" );
