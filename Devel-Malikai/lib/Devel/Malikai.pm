package Devel::Malikai;

use warnings;
use strict;

=head1 NAME

Devel::Malikai

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

BEGIN {
 use Exporter    ();
 our  ($VERSION, @ISA, @EXPORT, @EXPORT_OK);
 $VERSION = 0.10;
 @ISA  = qw(Exporter);
 @EXPORT_OK = qw( hashdump logger );
 @EXPORT  = qw( hashdump logger );
}
our @EXPORT_OK;

sub hashdump {
 if ( @_ ) {
 my $inputnum = 1;
 foreach my $input (@_) {
	my $type = ref($input);
  logger("HASHDUMP: dumping input $inputnum, type $type");
  if ( $input ) {
   if ( ref($input) eq 'HASH' ) {
    foreach my $key (sort(keys(%{ $input })) ) {
     if ( $input->{$key} ) {
      logger("HASHDUMP: HASH: $key => $input->{$key}");
     } else {
      logger("HASHDUMP: HASH: $key => NULL");
     }
    }
    } elsif ( ref($input) eq 'ARRAY' ) {
     my $line = join ' ', @{ $input };
     logger("HASHDUMP: ARRAY: $line");
    } elsif ( ref($input) eq 'SCALAR' ) {
     logger("HASHDUMP: SCALAR: $input");
    } else {
     logger("HASHDUMP: UNKNOWN: $input");
    }
   } else {
    logger("HASHDUMP: NULL variable");
   }
   $inputnum++;
  }
  return(0);
 } else {
  logger("HASHDUMP: NULL INPUT");
  return(0);
 }
}

sub logger {
	foreach my $message (@_) {
		print "$0: $message\n";
	}
	return(1);
}

=head1 AUTHOR

Malikai, C<< <malikai at art1st> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-devel-malikai at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Devel-Malikai>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Devel::Malikai


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Devel-Malikai>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Devel-Malikai>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Devel-Malikai>

=item * Search CPAN

L<http://search.cpan.org/dist/Devel-Malikai/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2011 Malikai.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Devel::Malikai
