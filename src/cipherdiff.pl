#! /usr/local/bin/perl -T
#
# Originally written by Jan Schaumann <jschauma@netmeister.org>
# in October 2016.
#
# This little tool reports the differences between the
# cipher suites supported by the given server and the
# given spec.
#
# Copyright (c) 2016, Yahoo Inc.
# 
# Redistribution and use in source and binary forms,
# with or without modification, are permitted provided
# that the following conditions are met:
# 
# 1. Redistributions of source code must retain the
# above copyright notice, this list of conditions and
# the following disclaimer.
# 
# 2. Redistributions in binary form must reproduce the
# above copyright notice, this list of conditions and
# the following disclaimer in the documentation and/or
# other materials provided with the distribution.
#
# 3. Neither the name of the copyright holder nor the
# names of its contributors may be used to endorse or
# promote products derived from this software without
# specific prior written permission.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND
# CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED
# WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
# PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL
# THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY
# DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
# PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF
# USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER
# IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
# NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
# USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.

use warnings;
use strict;

use File::Basename;
use File::Temp qw(tempfile);
use Term::ANSIColor;

use Getopt::Long;
Getopt::Long::Configure("bundling");

$ENV{'PATH'} = "/bin:/usr/bin:/sbin:/usr/sbin:/usr/local/bin:/usr/local/sbin";

###
### Constants
###

use constant TRUE => 1;
use constant FALSE => 0;

use constant EXIT_FAILURE => 1;
use constant EXIT_SUCCESS => 0;

###
### Globals
###

my %OPTS = (
		'openssl' => "openssl",
		'spec'    => ""
	   );
my $PROGNAME = basename($0);
my $VERSION = "1.3";

my %CLIENT_CIPHERS;
my %CIPHERS_BY_PROTOCOL;
my %SUPPORTED_CIPHERS;
my %UNKNOWN_CIPHERS;
my %UNSUPPORTED_CIPHERS;
my %WANTED_CIPHERS;
my %WEIGHTED_CIPHERS;

my $RETVAL = 0;

###
### Subroutines
###

sub colorReport() {
	my %out;

	my @serverCiphers = sortedKeys(\%WEIGHTED_CIPHERS);
	my @spec = split(":", $OPTS{'spec'});
	my %specCiphers = map { $_ => 1 } @spec;

	my $n = 0;
	foreach my $c (@serverCiphers) {
		if (!$specCiphers{$c}) {
			my %h = ( wanted => -1, found => $n );
			$out{$c} = \%h;
		}
		$n++;
	}

	my $wantedPosition = 0;
	foreach my $a (@spec) {
		my $foundPosition = 0;
		my $n = 0;
		my $found = 0;
		foreach my $b (@serverCiphers) {
			if ($a eq $b) {
				$found = 1;
				$foundPosition = $n;
				last;
			}
			$n++;
		}

		if ($found) {
			my %h = ( wanted => $wantedPosition, found => $foundPosition );
			$out{$a} = \%h;
		}
		$wantedPosition++;
	}

	my %extra;
	$n = 0;
	foreach my $c (@spec) {
		if (!$out{$c}) {
			$extra{$c} = $n;
		}
		$n++;
	}

	my @ciphers = sortWantedFound(\%out);
	$n = scalar(@ciphers);

	my $i = 0;
	my $e = 0;

	my $output = "";

	foreach my $c (@ciphers) {
		my %h = %{$out{$c}};

		foreach my $ec (keys(%extra)) {
			if ($extra{$ec} == $i) {
				$output .= colored($ec, 'blue');
				if ($n > 1) {
					$output .= ":";
				}
				delete($extra{$ec});
				$e++;
				$RETVAL = 2;
			}
		}

		my $found = $h{'found'} - $e;
		if ($h{'wanted'} == -1) {
			$output .= colored($c, 'magenta');
			$RETVAL = 2;
			$e--;
		} elsif ($h{'wanted'} == $found) {
			$output .= $c;
		} elsif ($h{'wanted'} > $found) {
			$output .= colored($c, 'yellow');
			$RETVAL = 2;
		} elsif ($h{'wanted'} < $found) {
			$output .= colored($c, 'red');
			$RETVAL = 2;
		}

		if ($n > 1) {
			$output .= ":";
		}
		$n--;
		$i++;
	}

	if ($RETVAL == 2) {
		print $output . "\n";
	}
}

# Take two cipher suites and return the preferred cipher.
sub compareTwo($$) {
	my ($a, $b) = @_;

	verbose("Comparing $a <=> $b...", 4);

	my $openssl = $OPTS{'openssl'};
	my $command = "</dev/null $openssl s_client -cipher $a:$b " .
				"-servername " . $OPTS{'sni'} . " -connect " .
				$OPTS{'host'} . ":" . $OPTS{'port'} . " 2>&1";

	my $out = `$command`;

	if ($out =~ m/New,.*Cipher is (.*)/) {
		my $selected = $1;
		if ($selected eq $a) {
			return $a;
		} elsif ($selected eq $b) {
			return $b;
		} else {
			return "indeterminate ($a:$b)";
		}
	} else {
		return "fail ($a:$b)";
	}
}

sub compareToSpec() {
	if (!$OPTS{'spec'}) {
		return;
	}

	if ($OPTS{'color'}) {
		colorReport();
	} elsif ($OPTS{'diff'}) {
		diffReport();
	} else {
		plainReport();
	}
}

sub determineOrder() {
	if (!$OPTS{'preference'}) {
		return;
	}

	my @set = keys(%SUPPORTED_CIPHERS);
	while (scalar(@set)) {
		my $next = shift(@set);
		weighOneCipher($next, @set);
	}
}

sub diffReport() {
	my @serverCiphers = sortedKeys(\%WEIGHTED_CIPHERS);
	my @spec = split(":", $OPTS{'spec'});

	my ($fh1, $specFile) = tempfile(UNLINK => 1);
	my ($fh2, $serverFile) = tempfile(UNLINK => 1);

	print $fh1 join("\n", @spec) . "\n";
	print $fh2 join("\n", @serverCiphers) . "\n";

	my $output = `diff -u $specFile $serverFile`;

	$output =~ s/^--- .*/--- given spec/;
	$output =~ s/\+\+\+ .*/\+\+\+ server/;

	print $output;

	close($fh1);
	close($fh2);

	if (length($output)) {
		$RETVAL = 2;
	}
}

sub identifyListOfCiphers() {
	my $openssl = $OPTS{'openssl'};

	my $out = `$openssl ciphers ALL:COMPLEMENTOFALL`;
	$out =~ s/:$//;
	chomp($out);

	%CLIENT_CIPHERS = map { $_ => 1 } split(":", $out);
	%WANTED_CIPHERS = map { $_ => 1 } split(":", $OPTS{'spec'});

	my %protocol_flags;
	if ($OPTS{'line'}) {
		foreach my $p (qw/ssl2 ssl3 tls1 tls1_1 tls1_2 tls1_3/) {
			if (opensslSupports($p)) {
				$protocol_flags{"-${p}"} = 1;
			} else {
				print STDERR "Warning: '-$p' not supported by " . $OPTS{'openssl'} . " s_client, skipping.\n";
			}
		}
	} else {
		$protocol_flags{" "} = 1;
	}

	foreach my $c (keys(%CLIENT_CIPHERS)) {
		verbose("Testing '$c'...");

		foreach my $flag (keys(%protocol_flags)) {

			my $selectFlag = "-cipher";
			if ($flag =~ m/^-/) {
				verbose("Trying with '$flag'...", 2);
			}
			if (!$protocol_flags{$flag}) {
				next;
			}

			if ($flag eq "-tls1_3") {
				$selectFlag = "-ciphersuites";
			}

			my $sniFlags = "-servername " . $OPTS{'sni'};

sni:
			my $command = "</dev/null $openssl s_client $flag $selectFlag $c $sniFlags" .
				" -connect " . $OPTS{'host'} . ":" . $OPTS{'port'} . " 2>&1";
			verbose("$command", 3);
			my $out = `$command`;

			if ($out =~ m/unknown option/) {
				$protocol_flags{$flag} = 0;
				next;
			} elsif ($out =~ m/Unable to set TLS servername extension/i) {
				verbose("Trying again without SNI...", 4);
				$sniFlags = "";
				goto sni;
			}

			# We can't just rely on the return code, since
			# connections can fail for any number of reasons.
			# What's more, s_client(1) may return 0 on handshake
			# failure.  Therefore, we have to do the janky thing
			# and parse stderr. :-/
			if ($out =~ m/New,.*Cipher is (\S+)/) {
				my $p = $1;

				if ($p =~ m/none/i) {
					verbose("'$c' not supported by the server when using $flag.");
					$UNSUPPORTED_CIPHERS{$c} = 1;
					next;
				}

				if ($p ne $c) {
					verbose("Tried '$c', but got '$p'?");
					next;
				}

				if ($OPTS{'line'}) {
					$p = uc($flag);
					$p =~ s/-//;
					$p =~ s/_/./;
				}
				if (!defined($SUPPORTED_CIPHERS{$c})) {
					$SUPPORTED_CIPHERS{$c} = [];
				}
				push(@{$SUPPORTED_CIPHERS{$c}}, $p);

				if (!defined($CIPHERS_BY_PROTOCOL{$p})) {
					$CIPHERS_BY_PROTOCOL{$p} = [];
				}
				push(@{$CIPHERS_BY_PROTOCOL{$p}}, $c);
			} elsif ($out =~ m/(alert|ssl) (protocol version|handshake failure)|no cipher(s available| match)/i) {
				verbose("'$c' not supported by the server when using $flag.");
				$UNSUPPORTED_CIPHERS{$c} = 1;
			} elsif ($out =~ m/(.*)\nconnect:errno=\d+/mi) {
				print STDERR "Unable to connect to ". $OPTS{'host'} . " on port " .
						 $OPTS{'port'} . ": $1\n";
				exit(EXIT_FAILURE);
				# NOTREACHED
			} elsif ($out =~ m/write:errno=54/i) {
				print STDERR "Server reset connection. Unable to determine support for '$c'.\n";
			} elsif ($out =~ m/:wrong version number/mi) {
				# When checking multiple protocols, version
				# mismatches are expected.
				;
			} else {
				print "Unexpected output for $c:\n";
				print "|$out|\n";
			}

			sleepIfNeeded();
		}
	}
}


sub init() {
	my ($ok);

	$ok = GetOptions(
			"Delay|D=i"	=> \$OPTS{'delay'},
			"SNI|S=s"       => \$OPTS{'sni'},
			"Version|V"     => sub { print "$PROGNAME: $VERSION\n"; exit(EXIT_SUCCESS); },
			"color|c"       => \$OPTS{'color'},
			"diff|d"        => sub { $OPTS{'diff'} = 1; $OPTS{'preference'} = 1; },
			"help|h"        => \$OPTS{'help'},
			"list|l"        => \$OPTS{'line'},
			"openssl|o=s"   => \$OPTS{'openssl'},
			"pref|p"        => \$OPTS{'preference'},
			"spec|s=s"      => \$OPTS{'spec'},
			"tls|t"         => sub { $OPTS{'protocols'} = 1; $OPTS{'line'} = 1; },
			"unsupported|u" => \$OPTS{'unsupported'},
			"verbose|v"     => sub { $OPTS{'verbose'}++; },
		);

	if ($OPTS{'help'} || !$ok) {
		usage($ok);
		exit(!$ok);
		# NOTREACHED
	}

	if (!scalar(@ARGV)) {
		print STDERR "Please specify a hostname or IP address.\n";
		exit(EXIT_FAILURE);
		# NOTREACHED
	}

	if ($OPTS{'diff'} && !$OPTS{'spec'}) {
		print STDERR "'-d' requires '-s'.\n";
		exit(EXIT_FAILURE);
		# NOTREACHED
	}

	if ($OPTS{'unsupported'} && $OPTS{'preference'}) {
		print STDERR "'-p' and '-u' are mutually exclusive.\n";
		exit(EXIT_FAILURE);
		# NOTREACHED
	}

	if (($OPTS{'line'} || $OPTS{'protocols'}) && $OPTS{'spec'}) {
		print STDERR "'-l'/'-t' and '-s' are mutually exclusive.\n";
		exit(EXIT_FAILURE);
		# NOTREACHED
	}

	if (!$OPTS{'spec'} && !$OPTS{'unsupported'}) {
		$OPTS{'list'} = 1;
	}

	$OPTS{'host'} = $ARGV[0];
	$OPTS{'port'} = $ARGV[1] ? $ARGV[1] : 443;

	if ($OPTS{'host'} =~ m/^([^:]+):(\d+)$/) {
		$OPTS{'host'} = $1;
		$OPTS{'port'} = $2;
	}

	if ($OPTS{'host'} =~ m/^([a-z0-9.:_-]+)$/i) {
		$OPTS{'host'} = $1;
	} else {
		print STDERR "Invalid hostname: " . $OPTS{'host'} . "\n";
		exit(EXIT_FAILURE);
		# NOTREACHED
	}

	if ($OPTS{'port'} =~ m/^(\d+)$/) {
		$OPTS{'port'} = $1;
	} else {
		print STDERR "Invalid port: " . $OPTS{'port'} . "\n";
		exit(EXIT_FAILURE);
		# NOTREACHED
	}

	if ($OPTS{'sni'}) {
		if ($OPTS{'sni'} =~ m/^([a-z0-9.:_-]+)$/i) {
			$OPTS{'sni'} = $1;
		} else {
			print STDERR "Invalid SNI: " . $OPTS{'sni'} . "\n";
			exit(EXIT_FAILURE);
			# NOTREACHED
		}
	} else {
		$OPTS{'sni'} = $OPTS{'host'};
	}

	if ($OPTS{'openssl'}) {
		# Yes, this is only a subset of valid pathnames,
		# but it's good enough and lets us untaint the var.
		if ($OPTS{'openssl'} =~ m|^([a-z0-9\@_/.-]+)$|i) {
			$OPTS{'openssl'} = $1;
		} else {
			print STDERR "Invalid pathname '" . $OPTS{'openssl'} . "'.\n";
			exit(EXIT_FAILURE);
			# NOTREACHED
			
		}
	}
}

sub listCiphers(@) {
	my @ciphers = @_;
	if ($OPTS{'protocols'}) {
		# This is messy.  We need to go by protocol,
		# but we want to retain preference order, so we
		# need to go one by one and pick the matching
		# ciphers from the preference order.
		foreach my $p (sort(keys(%CIPHERS_BY_PROTOCOL))) {
			my @p_ciphers = @{$CIPHERS_BY_PROTOCOL{$p}};
			if (scalar(@p_ciphers)) {
				print "$p: ";
				my @all_ciphers = @ciphers;
				while(scalar(@all_ciphers)) {
					my $c1 = shift(@all_ciphers);
					foreach my $c2 (@p_ciphers) {
						if ($c1 eq $c2) {
							print $c1;
							if (scalar(@all_ciphers)) {
								print " ";
							}
							last;
						}
					}
				}
				print "\n";
			}
		}
	} else {
		foreach my $c (@ciphers) {
			print "$c: " . join(" ", sort(@{$SUPPORTED_CIPHERS{$c}})) . "\n";
		}
	}
}

sub opensslSupports($) {
	my ($p) = @_;
	verbose("Checking if " . $OPTS{'openssl'} . " supports $p...", 3);

	my $command = "</dev/null " . $OPTS{'openssl'} . " s_client -$p 2>&1";
	my $out = `$command`;

	if (($? == -1) || ($out =~ m/^sh: /)) {
		print STDERR "Unable to run '$command'. Aborting.\n";
		exit(EXIT_FAILURE);
	}

	if ($out =~ m/unknown option.*-$p/i) {
		return FALSE;
	}
	return TRUE;
}

sub plainReport() {
	my @shared;
	foreach my $c (sort(keys(%SUPPORTED_CIPHERS))) {
		if ($WANTED_CIPHERS{$c}) {
			push(@shared, $c);
		}
	}

	my $p = 0;
	if (scalar(@shared)) {
		$p = 1;
		print "Shared ciphers: " . join(":", @shared) . "\n"
	}

	print $p ? "\n" : "";
	$p = 0;

	foreach my $c (sort(keys(%WANTED_CIPHERS))) {
		if (!$CLIENT_CIPHERS{$c}) {
			$p = 1;
			print "In input spec, but not supported by local openssl version: $c\n";
			$UNKNOWN_CIPHERS{$c} = 1;
			$RETVAL = 2;
		}
	}

	print $p ? "\n" : "";
	$p = 0;

	foreach my $c (sort(keys(%WANTED_CIPHERS))) {
		if (!$SUPPORTED_CIPHERS{$c} && !$UNKNOWN_CIPHERS{$c}) {
			$p = 1;
			print "In input spec, but not supported by server: $c\n";
			$RETVAL = 2;
		}
	}

	print $p ? "\n" : "";
	$p = 0;

	foreach my $c (sort(keys(%SUPPORTED_CIPHERS))) {
		if (!$WANTED_CIPHERS{$c}) {
			$p = 1;
			print "Supported by server, but not in input spec: $c\n";
			$RETVAL = 2;
		}
	}

	if ($OPTS{'preference'}) {
		my @serverCiphers = sortedKeys(\%WEIGHTED_CIPHERS);
		my $weighted = join(":", @serverCiphers);

		if ($weighted ne $OPTS{'spec'}) {
			print $p ? "\n" : "";
			print "Input spec and server preference differ.\n";
			print "Input spec:\n";
			print $OPTS{'spec'} . "\n";
			print "===\n";
			print "Observed preference:\n";
			print "$weighted\n";
			$RETVAL = 2;
		}
	}
}

sub printCipherList() {
	my @ciphers;

	if (!$OPTS{'preference'} && ($OPTS{'list'} || $OPTS{'unsupported'})) {
		my %which = %SUPPORTED_CIPHERS;
		if ($OPTS{'unsupported'}) {
			%which = %UNSUPPORTED_CIPHERS;
		}
		@ciphers = sort(keys(%which));

	} elsif ($OPTS{'list'} && $OPTS{'preference'}) {
		@ciphers = sortedKeys(\%WEIGHTED_CIPHERS);
	}

	if (scalar(@ciphers)) {
		if ($OPTS{'line'}) {
			listCiphers(@ciphers);
		} else {
			print join(":", @ciphers) . "\n";
		}
	} else {
		if ($OPTS{'list'}) {
			print "No shared ciphers between client and server.\n";
		}
	}
}

sub sleepIfNeeded() {
	if ($OPTS{'delay'}) {
		verbose("Sleeping " . $OPTS{'delay'} . " seconds...", 2);
		sleep($OPTS{'delay'});
	}
}

# function : sortedKeys
# purpose  : return a sorted array of keys for the given hash
# input    : a hash; optionally: whether or not to sort in ascending order
# output   : an array of the keys sorted numerically / lexically.

sub sortedKeys($;$) {
	my ($hr, $ascending) = @_;
	my %hash = %{$hr};
	my @keys;

	if ($ascending) {
		@keys = sort { $hash{$a} <=> $hash{$b} } keys(%hash);
	} else {
		@keys = sort { $hash{$b} <=> $hash{$a} } keys(%hash);
	}

	return @keys;
}

sub sortWantedFound($) {
	my ($hr) = @_;
	my %hash = %{$hr};
	my @keys;

	@keys = sort { $hash{$a}{'found'} <=> $hash{$b}{'found'} } keys(%hash);

	return @keys;
}

sub usage($) {
	my ($err) = @_;

	my $FH = $err ? \*STDERR : \*STDOUT;

	print $FH <<EOH
Usage: $PROGNAME [-Vcdhlptuv] [-D seconds] [-S sni] [-o openssl] [-s spec] server [port]
  -D seconds  sleep seconds in between connections
  -S sni      set server name indication to use
  -V          print version information and exit
  -c          display differences in color
  -d          list differences using diff(1)
  -h          print this help and exit
  -l          list ciphers one per line
  -o openssl  use this openssl binary
  -p          compare or list preference order
  -s spec     compare to this spec
  -t          like '-l', but sort by protocol
  -u          list ciphers not supported by the server
  -v          be verbose
EOH
;

}

sub verbose($;$) {
	my ($msg, $level) = @_;
	my $char = "=";

	return unless $OPTS{'verbose'};

	$char .= "=" x ($level ? ($level - 1) : 0 );

	if (!$level || ($level <= $OPTS{'verbose'})) {
		print STDERR "$char> $msg\n";
	}
}

sub weighOneCipher($@) {
	my ($a, @rest) = @_;

	verbose("Weighing $a against " . scalar(@rest) . " ciphers...", 2);
	if ((scalar(@rest) == 0) && !$WEIGHTED_CIPHERS{$a}) {
		$WEIGHTED_CIPHERS{$a} = 0;
	} else {
		foreach my $b (@rest) {
			if (!$WEIGHTED_CIPHERS{$a}) {
				$WEIGHTED_CIPHERS{$a} = 0;
			}
			if (!$WEIGHTED_CIPHERS{$b}) {
				$WEIGHTED_CIPHERS{$b} = 0;
			}
			my $preferred = compareTwo($a, $b);
			$WEIGHTED_CIPHERS{$preferred}++;
			verbose("Preferring $a over $b.", 3);
			verbose("$a: " . $WEIGHTED_CIPHERS{$a}, 4);
			verbose("$b: " . $WEIGHTED_CIPHERS{$a}, 4);
			sleepIfNeeded();
		}
	}
}

###
### Main
###

init();
identifyListOfCiphers();
determineOrder();
compareToSpec();
printCipherList();

exit($RETVAL);
