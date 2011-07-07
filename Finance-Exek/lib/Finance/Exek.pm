package Finance::Exek;

use warnings;
use strict;

use Devel::Malikai;

use Carp;
use JSON;
use Switch;
use IO::Async::Loop;
use IO::Async::SSL;

my $state;

=head1 NAME

Finance::Exek - exek.net market data and trading high level client module.

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

This module provides an asynchronus IO loop and upper level methods for communication
with the exek.net exchange. This module should not be loaded directly by programs.
Instead, the apropriate low level module such as Finance::Exek::WebSocket should be
loaded.

The callbacks listed below on the left are available. When a corresponding message is
received from the exchange, the callback will be executed with the arguments and types
shown on the right. Connection state is maintained internally within the Exek:: modules.

    connect_fail    -> undef,scalar(reason)
    login_success   -> object(self)
    account_balance -> object(self),hashref(account)
    symbol_list     -> object(self),array(symbol names)
    order_rejected  -> object(self),hashref(ticket)
    order_accepted  -> object(self),hashref(ticket),integer(order ID)
    order_execution -> object(self),integer(order ID), integer(amount)
    order_deleted   -> object(self),integer(order ID)
    order_list      -> object(self),array(hashref(open order))
    position_list   -> object(self),array(hashref(open position))
    delta           -> object(self),hashref(subscriptions), hashref(changes)

NOTE: All of the callbacks are optional.

=head1 METHODS

=head2 default()

stuff

=cut

sub default {
	my ($self,$in) = @_;
	return $in;
}

=head2 quote()

This will return a hashref of the full order book for the given symbol.

  my $quote = $exek->quote("symbolname");

  $quote will look like:
  {
    bids => {
     price => amount
     price => amount
     ...   => ...
    }
    asks =>{
     price => amount
     price => amount
     ...   => ...
    }
  }

=cut

sub quote {
	my ($self,$in) = @_;
	if ( $in ) {
		if ( $self->{xids}->{$in} ) {
			return $self->{xids}->{$in};
		} else {
			carp "Symbol not subscribed";
			return undef;
		}
	} else {
		carp "Symbol not specified";
		return undef;
	}
}

=head2 order_new()

This method will submit a list of new order tickets to the exchange.
Notes:
  - Price is an integer in minimum denomination. Example: shitoshis, cents, pence, etc.
  - Quantity is an integer.

  my $ticket1 = {
    action   => '(buy|sell)',
    type     => '(market|limit)',
    symbol   => 'symbolname',
    price    => '1',
    quantity => '1'
  };

  my $ticket2 = { ... };

  $exek->order_new($ticket1,$ticket2);

=cut

sub order_new {
	my ($self,@tickets) = @_;

	foreach my $ticket (@tickets) {

		if ( ! $ticket->{action} ) { croak "Missing order action"; }
		if ( ! $ticket->{type} ) { croak "Missing order type"; }
		if ( ! $ticket->{symbol} ) { croak "Missing symbol"; }
		if ( ! $ticket->{quantity} ) { croak "Missing quantity"; }

		if ( $ticket->{type} eq 'limit' && $ticket->{price} < 1 ) {
			croak "Missing price on limit order";
		} elsif ( $ticket->{type} eq 'market' ) {
			$ticket->{price} = 0;
		}

		my $message = _encode( {
			type	=> 'order',
			order	=> {
				action	=> $ticket->{action},
				type		=> $ticket->{type},
				xid			=> $ticket->{xid},
				price		=> $ticket->{price},
				qty			=> $ticket->{quantity}
			}
		} ) or croak "Failed to encode message";

		$state->{client}->send_frame($message);
	}

	return 1;
}

=head2 order_delete()

This will request to delete a specified order from the exchange. Expected
argument is an Order ID.

  $exek->order_delete(order_id);

=cut

sub order_delete {
	my ($self,@oids) = @_;

	foreach my $oid (@oids) {
		my $message = _encode( {
			type	=> 'delete',
			oid		=> $oid
		} );

		$state->{client}->send_frame($message);
	}

	return 1;
}

=head2 list_symbols()

The list_symbols method will request a list of symbols traded on the exchange.

=cut

sub list_symbols {
	my ($self,$in) = @_;

	my $message = _encode( {
		type => 'list_xids'
	} );

	$state->{client}->send_frame($message);

	return 1;
}

=head2 subscribe()

This will request a subscription to market data for a given symbol.

  $exek->subscribe("symbol");

=cut

sub subscribe {
	my ($self,$in) = @_;

	if ( $in ) {
		my $message = _encode( {
			type => 'subscribe',
			xid => $in
		} );

		$state->{client}->send_frame($message);

	} else {
		carp "No symbol requested";
		return undef;
	}

	return 1;
}

sub _configure {
	my ($self,$in) = @_;
	$state = $self;
	$state->{conf} = {};
	$state->{callbacks} = $in->{callbacks};
	my $conf = $state->{conf};

	if ( $in->{username} && $in->{password} ) {
		$conf->{username} = $in->{username};
		$conf->{password} = $in->{password};

		if ( $in->{hostname} ) {
			$conf->{hostname} = $in->{hostname};
		} else {
			$conf->{hostname} = 'ws.exek.net';
		}

		if ( $in->{port} ) {
			$conf->{port} = $in->{port};
		} else {
			$conf->{port} = '443';
		}
	} else {
		carp "Username or password missing";
		return undef;
	}

	return 1;
}

sub _rcv_symbols {
	my ($self,$in) = @_;

	if ( ref($state->{callbacks}->{rcv_symbols}) eq 'CODE' ) {
		$state->{callbacks}->{rcv_symbols}($state,@{ $in->{symbols} });
	}

	return 1;
}

sub _io_loop {
	my ($self,$in) = @_;

	if ( $state->{client} ) {
		$state->{loop} = IO::Async::Loop->new;
		$state->{loop}->add( $state->{client} );
	} else {
		croak "Client not set up";
	}

	return 1;
}

sub _delta {
	my ($deltas) = @_;

	unless ( $state->{xids} ) {
		$state->{xids} = {};
	}
  my $xids = $state->{xids};

	foreach my $side ( 'asks', 'bids' ) {
		if ( $deltas->{$side} ) {
			foreach my $delta ( @{ $deltas->{$side} } ) {

				my $xidname = $deltas->{xid};
				unless ( $xids->{$xidname} ) {
					$xids->{$xidname} = {};
				}
				my $xid = $xids->{$xidname};

				if ( $delta->{action} eq 'add' ) {
					if ( ! $xid->{$side} ) {
						$xid->{$side} = {};
					}
					$xid->{$side}->{$delta->{price}} = $delta->{amt};
				} elsif ( $delta->{action} eq 'delete' ) {
					delete($xid->{$side}->{$delta->{price}});
				} elsif ( $delta->{action} eq 'replace' ) {
					$xid->{$side}->{$delta->{price}} = $delta->{amt};
				}
			}
		}
	}

	if ( ref($state->{callbacks}->{delta}) eq 'CODE' ) {
		$state->{callbacks}->{delta}($state,$deltas);
	}

	return 1;
}

sub _symbol_list {
	@{ $state->{symbols} } = @_;

	if ( ref($state->{callbacks}->{symbol_list}) eq 'CODE' ) {
		$state->{callbacks}->{symbol_list}($state,@_);
	}

	return 1;
}

sub _order_confirm {
	push @{ $state->{orders} }, @_;

	if ( ref($state->{callbacks}->{order_confirm}) eq 'CODE' ) {
		$state->{callbacks}->{order_confirm}($state,@_);
	}

	return 1;
}

sub _order_execution {
	push @{ $state->{positions} }, @_;

	if ( ref($state->{callbacks}->{order_execution}) eq 'CODE' ) {
		$state->{callbacks}->{order_execution}($state,@_);
	}
}

sub _order_rejected {
	if ( ref($state->{callbacks}->{order_rejected}) eq 'CODE' ) {
		$state->{callbacks}->{order_rejected}($state,@_);
	}

	return 1;
}

sub _order_deleted {
	if ( ref($state->{callbacks}->{order_deleted}) eq 'CODE' ) {
		$state->{callbacks}->{order_deleted}($state,@_);
	}

	return 1;
}

sub _order_list {
	if ( ref($state->{callbacks}->{order_list}) eq 'CODE' ) {
		$state->{callbacks}->{order_list}($state,@_);
	}

	return 1;
}

sub _account_balance {
	if ( ref($state->{callbacks}->{account_balance}) eq 'CODE' ) {
		$state->{callbacks}->{account_balance}($state,@_);
	}

	return 1;
}

sub _position_list {
	if ( ref($state->{callbacks}->{position_list}) eq 'CODE' ) {
		$state->{callbacks}->{position_list}($state,@_);
	}

	return 1;
}

sub _login_request {
	my $login = _encode( {
		type => 'login',
		auth => {
			username => $state->{conf}->{username},
			password => $state->{conf}->{password}
		}
	} );

	$state->{client}->send_frame($login);

	return 1;
}

sub _login_response {
	my ($message) = @_;
	my $callbacks = $state->{callbacks};

	if ( $message->{result} ) {

		if ( ref($callbacks->{login_success}) eq 'CODE' ) {
			$callbacks->{login_success}($state);
		}
	} else {
		croak "login failed";
	}

	return 1;
}

sub _rcv_json {
	my ( $client, $frame ) = @_;
	my $self = $state->{exek};

	if ( my $message = _decode($frame) ) {

		switch($message->{type}) {
			case 'delta'	{ _delta($message) }
			case 'xidls'	{ _symbol_list($message) }
			case 'oconf'	{ _order_confirm($message) }
			case 'orexe'	{ _order_execution($message) }
			case 'orrej'	{ _order_rejected($message) }
			case 'ordel'	{ _order_delete($message) }
			case 'ordls'	{ _order_list($message) }
			case 'acbal'	{ _account_balance($message) }
			case 'posls'	{ _position_list($message) }
			case 'login'	{ _login_response($message) }
		}

	} else {
		carp ("failed to decode json frame $!");
		return undef;
	}

	return 1;
}

sub _encode {
	my ($in) = @_;
  if ( my $encoded = encode_json($in) ) {
		return $encoded;
	} else {
		croak "Failed to encode JSON message in $in";
		return undef;
	}
}

sub _decode {
	my ($in) = @_;
	if ( my $decoded = decode_json($in) ) {
		return $decoded;
	} else {
		carp "Failed to decode JSON message in $in";
		return undef;
	}
}

=head1 AUTHOR

Jason Ihde, C<< <jason at ihde.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-finance-exek at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Finance-Exek>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Finance::Exek


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Finance-Exek>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Finance-Exek>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Finance-Exek>

=item * Search CPAN

L<http://search.cpan.org/dist/Finance-Exek/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2011 Jason Ihde.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Finance::Exek
