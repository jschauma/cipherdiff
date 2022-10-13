cipherdiff
==========

This tool allows you to compare the list of SSL/TLS
ciphers offered by a server to a given cipher spec.

The output can identify ciphers supported by the
server but not listed in the spec, ciphers listed in
the spec but not supported by the server, as well as
discrepancies in the cipher order of the server versus
the given spec.

Please see the
[man page](https://raw.githubusercontent.com/jschauma/cipherdiff/master/doc/cipherdiff.txt)
for details.

If you have questions, comments, or suggestions,
please contact the author at
[jschauma@netmeister.org](mailto:jschauma@netmeister.org)
or at [@jschauma](https://twitter.com/jschauma).

## Requirements

`cipherdiff(1)` is written in Perl and requires
OpenSSL to be installed.


## Installation

To install the command and manual page somewhere
convenient, run `make install`; the Makefile defaults
to '/usr/local' but you can change the PREFIX:

```
$ make PREFIX=~ install
```

## Examples

### Listing ciphers in alphabetical order

To list the ciphers supported by the remote server in
alphabetical (default) order:

```
$ cipherdiff www.yahoo.com
AES128-GCM-SHA256:AES128-SHA:AES128-SHA256:AES256-GCM-SHA384:AES256-SHA:AES256-SHA256:DES-CBC3-SHA:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-SHA:ECDHE-RSA-AES128-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-SHA:ECDHE-RSA-AES256-SHA384
```

Note that the list of ciphers is necessarily
restricted to a subset of ciphers supported by the
client (i.e. openssl(1)).

### Using an alternate openssl(1)

If you have a different version of openssl(1)
installed, you can use that via the '-o' flag.  In the
following example, /tmp/openssl supports a much
shorter list of ciphers:

```
$ cipherdiff -o /tmp/openssl www.yahoo.com
AES128-SHA:AES256-SHA:DES-CBC3-SHA
```

### Listing ciphers in order of preference

To list the ciphers supported by the remote server in
order of preference:

```
$ cipherdiff -p www.yahoo.com
ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES128-SHA256:ECDHE-RSA-AES256-SHA384:ECDHE-RSA-AES128-SHA:ECDHE-RSA-AES256-SHA:AES128-GCM-SHA256:AES256-GCM-SHA384:AES128-SHA256:AES256-SHA256:AES128-SHA:AES256-SHA:DES-CBC3-SHA
```

### Listing ciphers not supported by the server

To list the ciphers _not_ supported by the remote
server, but available on the client side:

```
$ cipherdiff -u www.yahoo.com
CAMELLIA128-SHA:CAMELLIA256-SHA:DHE-DSS-AES128-GCM-SHA256:DHE-DSS-AES128-SHA:DHE-DSS-AES128-SHA256:DHE-DSS-AES256-GCM-SHA384:DHE-DSS-AES256-SHA:DHE-DSS-AES256-SHA256:DHE-DSS-CAMELLIA128-SHA:DHE-DSS-CAMELLIA256-SHA:DHE-DSS-SEED-SHA:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES128-SHA:DHE-RSA-AES128-SHA256:DHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-SHA:DHE-RSA-AES256-SHA256:DHE-RSA-CAMELLIA128-SHA:DHE-RSA-CAMELLIA256-SHA:DHE-RSA-SEED-SHA:ECDH-ECDSA-AES128-GCM-SHA256:ECDH-ECDSA-AES128-SHA:ECDH-ECDSA-AES128-SHA256:ECDH-ECDSA-AES256-GCM-SHA384:ECDH-ECDSA-AES256-SHA:ECDH-ECDSA-AES256-SHA384:ECDH-ECDSA-DES-CBC3-SHA:ECDH-ECDSA-RC4-SHA:ECDH-RSA-AES128-GCM-SHA256:ECDH-RSA-AES128-SHA:ECDH-RSA-AES128-SHA256:ECDH-RSA-AES256-GCM-SHA384:ECDH-RSA-AES256-SHA:ECDH-RSA-AES256-SHA384:ECDH-RSA-DES-CBC3-SHA:ECDH-RSA-RC4-SHA:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES128-SHA:ECDHE-ECDSA-AES128-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES256-SHA:ECDHE-ECDSA-AES256-SHA384:ECDHE-ECDSA-DES-CBC3-SHA:ECDHE-ECDSA-RC4-SHA:ECDHE-RSA-DES-CBC3-SHA:ECDHE-RSA-RC4-SHA:EDH-DSS-DES-CBC3-SHA:EDH-RSA-DES-CBC3-SHA:PSK-3DES-EDE-CBC-SHA:PSK-AES128-CBC-SHA:PSK-AES256-CBC-SHA:PSK-RC4-SHA:RC4-MD5:RC4-SHA:SEED-SHA:SRP-3DES-EDE-CBC-SHA:SRP-AES-128-CBC-SHA:SRP-AES-256-CBC-SHA:SRP-DSS-3DES-EDE-CBC-SHA:SRP-DSS-AES-128-CBC-SHA:SRP-DSS-AES-256-CBC-SHA:SRP-RSA-3DES-EDE-CBC-SHA:SRP-RSA-AES-128-CBC-SHA:SRP-RSA-AES-256-CBC-SHA
```

### Comparing to a cipher spec

If you have an existing cipher spec and want to verify
that the server follows it, you can pass it via the
'-s' flag:

```
$ cat /tmp/s
ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-SHA384:RC4-MD5:ECDHE-RSA-AES128-SHA:ECDHE-RSA-AES256-SHA:AES128-GCM-SHA256:AES256-GCM-SHA384:AES256-SHA256:AES128-SHA256:AES128-SHA:AES256-SHA:DES-CBC3-SHA
$ cipherdiff -s $(cat /tmp/s) -p www.yahoo.com
Shared ciphers:
AES128-GCM-SHA256:AES128-SHA:AES128-SHA256:AES256-GCM-SHA384:AES256-SHA:AES256-SHA256:DES-CBC3-SHA:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-SHA:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-SHA:ECDHE-RSA-AES256-SHA384

In input spec, but not supported by server: RC4-MD5

Supported by server, but not in input spec: ECDHE-RSA-AES128-SHA256

Input spec and server preference differ.
Input spec:
ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-SHA384:RC4-MD5:ECDHE-RSA-AES128-SHA:ECDHE-RSA-AES256-SHA:AES128-GCM-SHA256:AES256-GCM-SHA384:AES256-SHA256:AES128-SHA256:AES128-SHA:AES256-SHA:DES-CBC3-SHA
===
Observed preference:
ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES128-SHA256:ECDHE-RSA-AES256-SHA384:ECDHE-RSA-AES128-SHA:ECDHE-RSA-AES256-SHA:AES128-GCM-SHA256:AES256-GCM-SHA384:AES128-SHA256:AES256-SHA256:AES128-SHA:AES256-SHA:DES-CBC3-SHA
```

Since reading differences in a long cipher spec can be
difficult, you can also ask cipherdiff(1) to generate
unified diff(1) output, which humans may find easier
to read:

```
$ cipherdiff -d -s $(cat /tmp/s) -p www.yahoo.com
--- given spec
+++ server
@@ -1,13 +1,13 @@
 ECDHE-RSA-AES128-GCM-SHA256
 ECDHE-RSA-AES256-GCM-SHA384
+ECDHE-RSA-AES128-SHA256
 ECDHE-RSA-AES256-SHA384
-RC4-MD5
 ECDHE-RSA-AES128-SHA
 ECDHE-RSA-AES256-SHA
 AES128-GCM-SHA256
 AES256-GCM-SHA384
-AES256-SHA256
 AES128-SHA256
+AES256-SHA256
 AES128-SHA
 AES256-SHA
 DES-CBC3-SHA
```

You can also get the output marked up using terminal
color escape sequences using the '-c' flag:

Ciphers missing on the server but found in the spec
will be printed in blue, extra ciphers offered by
the server but not found in the spec in magenta, ciphers
that are deprioritized by the server compared to the
spec in red, and ciphers that are preferred by the
server over the spec in yellow:

![color example](https://raw.githubusercontent.com/jschauma/cipherdiff/master/doc/colorexample.png)

### Listing ciphers by protocol

When using the '-l' flag, cipherdiff(1) will print the
list of supported ciphers together with protocol
version.  This allows you to identify which
ciphersuites are supported when using each protocol:

```
$ cipherdiff.pl -p -l www.yahoo.com
ECDHE-RSA-AES128-GCM-SHA256: TLS1.2
ECDHE-RSA-AES256-GCM-SHA384: TLS1.2
ECDHE-RSA-AES128-SHA256: TLS1.2
ECDHE-RSA-AES256-SHA384: TLS1.2
ECDHE-RSA-AES128-SHA: TLS1 TLS1.1 TLS1.2
ECDHE-RSA-AES256-SHA: TLS1 TLS1.1 TLS1.2
AES128-GCM-SHA256: TLS1.2
AES256-GCM-SHA384: TLS1.2
AES128-SHA256: TLS1.2
AES128-SHA: TLS1 TLS1.1 TLS1.2
AES256-SHA: TLS1 TLS1.1 TLS1.2
AES256-SHA256: TLS1.2
DES-CBC3-SHA: TLS1 TLS1.1 TLS1.2
```

You can also generate output sorted by  protocol ('-t'):

```
$ cipherdiff.pl -p -t www.yahoo.com
TLS1: ECDHE-RSA-AES128-SHA ECDHE-RSA-AES256-SHA AES128-SHA AES256-SHA DES-CBC3-SHA 
TLS1.1: ECDHE-RSA-AES128-SHA ECDHE-RSA-AES256-SHA AES128-SHA AES256-SHA DES-CBC3-SHA 
TLS1.2: ECDHE-RSA-AES128-GCM-SHA256 ECDHE-RSA-AES256-GCM-SHA384 ECDHE-RSA-AES128-SHA256 ECDHE-RSA-AES256-SHA384 ECDHE-RSA-AES128-SHA ECDHE-RSA-AES256-SHA AES256-GCM-SHA384 AES128-SHA256 AES256-SHA256 AES128-SHA AES256-SHA DES-CBC3-SHA AES128-GCM-SHA256
```

As before, in either case the list of ciphers is
sorted in order of server preference if the '-p' flag
is given, or in alphabetical order if not.

---

```
NAME
     cipherdiff - diff ciphersuites between a server and a spec

SYNOPSIS
     cipherdiff [-Vcdhlptuv] [-D seconds] [-S sni] [-o openssl] [-s spec] server
		[port]

DESCRIPTION
     The cipherdiff tool will report the list of SSL and TLS ciphers supported
     by the given server in colon-separated, ordered format.  If an optional
     spec is provided via the -s flag, then cipherdiff will also report on the
     differences between what the server supports versus what the spec provides.

     If no port is specified, cipherdiff will connect to port 443 on the given
     server.

OPTIONS
     The following options are supported by cipherdiff:

     -D seconds	 Sleep for this many seconds in between connection attempts.
		 This can be useful if your defense mechanisms might otherwise
		 blacklist you for opening too many connections, but necessarily
		 slows down execution time of cipherdiff significantly.

     -S sni	 Specify the Server Name Indication to use.

     -V		 Print version information and exit.

     -c		 When reporting cipher preference differences, display
		 mismatches in color.  Ciphers missing on the server but found
		 in the spec will be printed in blue, extra ciphers offered by
		 the server but not found in the spec in magenta, ciphers that
		 are deprioritized by the server compared to the spec in red,
		 and ciphers that are preferred by the server over the spec in
		 yellow.

		 This is really only useful if the provided and observed specs
		 are sufficiently similar.

     -d		 Report differences in the cipher preferences via diff(1).

		 In this case, the cipher spec will be organized as a line-break
		 separated list and differences displayed in 'unified' output.

		 This flag implies -p.

     -h		 Display help and exit.

     -l		 When listing ciphers, print one cipher name per line.	This
		 will also display the protocol used for the cipher in question.

     -o openssl	 Use the openssl(1) binary found in this location.  If not
		 specified, cipherdiff will look in a conservatively set PATH of
		 the usual suspects.  (cipherdiff will not honor your PATH
		 environment variable since it runs with taint checking turned
		 on.)

     -p		 Perform a strict comparison to the given spec, accounting for
		 server preference.  This is slow (O(n^2) on the number of
		 ciphers supported by the openssl(1) library), as numerous
		 connections have to be made to the server.

     -s spec	 Diff the server's ciphersuite against the given spec.

     -t		 When listing supported ciphers, sort output by protocol.
		 Implies -l.

     -u		 List ciphers supported by the local openssl(1) command, but not
		 supported by the remote server.

     -v		 Be verbose.  Can be specified multiple times.

DETAILS
     Numerous tools exist to identify the different cipher suites and SSL/TLS
     protocols supported by a server.  However, in order to verify whether a
     remote server matches an exact cipher spec, one needs to iterate over all
     protocols and compare them to the given list.

     This process is very cumbersome, especially when attempted at any larger
     scale.  cipherdiff allows you to perform this task and report on the
     differences in a more convenient manner.  It does so by making multiple
     connections using the openssl(1) s_client(1) command and observing the
     cipher suite chosen by the server.

     In order to be able to test support for a given cipher suite, it
     necessarily must be supported by the local client (i.e. the openssl(1)
     library in use).  Results against the same server will thus vary depending
     on which cipher suites your library supports.

     Finally, when comparing a server's list of ciphers to a provided spec,
     cipherdiff will generate no output if the two match and simply return an
     exit status of 0.

EXAMPLES
     The following examples illustrate common usage of this tool.

     To merely report the cipher suites supported by www.example.com on port
     1234:

	   $ cipherdiff www.example.com 1234

     To list the cipher suites supported by www.example.com on port 443 in order
     of preference:

	   $ cipherdiff -p www.example.com
	   ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:...

     To list the ciphers not supported by the server:

	   $ cipherdiff -u www.example.com
	   CAMELLIA128-SHA:CAMELLIA256-SHA:DHE-DSS-AES128-GCM-SHA256:...

     To compare the cipher preference on the server against the one found in the
     file '/tmp/s':

	   $ cipherdiff -s $(cat /tmp/s) -p www.example.com
	   ...

     To list the ciphers supported by the server in preference order by
     protocol:

	   $ cipherdiff -t -p www.example.com
	   ...

EXIT STATUS
     The exit status of cipherdiff depends upon its invocation:

     When comparing cipher suites (i.e. the -s flag was given), then cipherdiff
     will return an exit status of 0 if no differences were found, an exit
     status of 1 if any errors were encountered, and an exit status of 2 if
     differences were found.

     When listing cipher suites, cipherdiff exits 0 on success, and >0 if an
     error occurred.

SEE ALSO
     openssl(1)

HISTORY
     cipherdiff was originally written by Jan Schaumann
     <jschauma@netmeister.org> in October 2016.

BUGS
     Please file bugs and feature requests by emailing the author.
```
