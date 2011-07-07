package Finance::Exek::WebSocket;

use Devel::Malikai;

use Carp;
use Net::Async::WebSocket::Client;

use base qw( Finance::Exek );

use strict;
use warnings;

my $state;

=head1 NAME

Finance::Exek::WebSocket - Low level websocket interface to exek.net.

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

This module implements the low level WebSocket protocol for the exek.net exchange.

    use Finance::Exek::WebSocket;

=head1 METHODS

=head2 default()

stuff

=cut

sub default {
}

=head2 new()

Create a new Exek::WebSocket connection object.

  my $callbacks = {
    connect_fail => \&connect_fail_handler,
    delta        => \&delta_handler,
    tick         => \&tick_handler
  };

  my $timers = {
    onesecond    => {
      wake  => 1,
      exec   => \&onesecond_timer
    },
    oneminute    => {
      wake  => 60,
      exec   => \&oneminute_timer
    }
  };

Callbacks and timers are listed above for reference only. See the Finance::Exek module for
the complete list.

  my $params = {
    username  => 'username',
    password  => 'password',
    hostname  => 'hostname',
    port      => '443',
    callbacks => $callbacks,
    timers    => $timers
  };

  my $exek = Finance::Exek::WebSocket->new($params);

NOTE: Username and password are required. Hostname and port default to
ws.exek.net port 443.

=cut

sub new {
	my ($self,$conf) = @_;
	$state = {};
	bless($state);

	$state->_configure($conf) or croak "Failed to configure: $!";

	if ( $state->_client() ) {
		;;
	} else {
		return undef;
	}
	if ( $state->_io_loop() ) {
		;;
	} else {
		return undef;
	}

	return($state);
}

=head2 connect()

This method connects to the exchange and begins the master IO loop. It will
return undef on connection loss, connection failure, or authentication failure. The
variable $! will contain any detail available about the failure. See Finance::Exek
for details about the master IO loop.

    $exek->connect();

=cut

sub connect {
	my ($self) = @_;

	my $client = $state->{client};
	my $loop = $state->{loop};

	my $host = $state->{conf}->{hostname};
	my $port = $state->{conf}->{port};
 
	$client->connect(
		host => $host,
		service => $port,
		url => "ws://$host:$port/bitcoin",

		on_connected => sub {
			$state->_login_request;
		},

		on_error => sub {
			croak "$!";
		},

		on_disconnect => sub {
			$loop->loop_stop;
		},

		on_connect_error => sub {
			$loop->loop_stop;
		},

		on_resolve_error => sub {
			$loop->loop_stop;
		}
	);

	unless ( $state->{loop}->loop_forever ) {
		carp "$!" if ( $! );
		return undef;
	}

	return undef;
}

sub _client {
	my ($self) = @_;

	$state->{client} = Net::Async::WebSocket::Client->new(
		on_frame => sub {
			my ( $self, $frame ) = @_;
			$state->_rcv_json($frame);
		}
	);

	return 1;
}

=head1 AUTHOR

Jason Ihde, C<< <jason at ihde.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-finance-exek-websocket at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Finance-Exek-WebSocket>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Finance::Exek::WebSocket


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Finance-Exek-WebSocket>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Finance-Exek-WebSocket>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Finance-Exek-WebSocket>

=item * Search CPAN

L<http://search.cpan.org/dist/Finance-Exek-WebSocket/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2011 Jason Ihde.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Finance::Exek::WebSocket
