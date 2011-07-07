#!/usr/bin/perl
use strict;
use warnings;

use Devel::Malikai;
use Finance::Exek::WebSocket;

$0 = "websocket";
my $state = {};

sub delta {
	my ($exek,$deltas) = @_;

	hashdump($exek->{xids}->{thusd});

	return 1;
}

sub login_success {
	my ($exek) = @_;

	logger("subscribing");
	$exek->subscribe("thusd");

	return 1;
}

sub main {
	my $callbacks = {
		delta 				=> \&delta,
		login_success	=> \&login_success
	};

	my $params = {
		username => 'username',
		password => 'password',
		hostname => 'ws.exek.net',
		port			=> 9000,
		callbacks	=> $callbacks
	};

	EXEK: while ( 1 ) {
		if ( my $exek = Finance::Exek::WebSocket->new($params) ) {
			logger("connecting");
			$exek->connect;	
			sleep(4);
		} else {
			logger("failed to setup: $!");
			last EXEK;
		}
	}
}

main(@ARGV);

