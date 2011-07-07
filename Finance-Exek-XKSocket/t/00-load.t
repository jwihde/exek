#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Finance::Exek::XKSocket' ) || print "Bail out!
";
}

diag( "Testing Finance::Exek::XKSocket $Finance::Exek::XKSocket::VERSION, Perl $], $^X" );
