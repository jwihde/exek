#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Finance::Exek::WebSocket' ) || print "Bail out!
";
}

diag( "Testing Finance::Exek::WebSocket $Finance::Exek::WebSocket::VERSION, Perl $], $^X" );
