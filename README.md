cipherdiff
==========

This tool allows you to compare the list of SSL/TLS
ciphers offered by a server to a given cipher spec.

The output can identify ciphers supported by the
server but not listed in the spec, ciphers listed in
the spec but not supported by the server, as well as
discrepancies in the cipher order of the server versus
the given spec.

Examples
--------

To list the ciphers supported by the remote server in
alphabetical (default) order:

```
$ cipherdiff www.yahoo.com
AES128-GCM-SHA256:AES128-SHA:AES128-SHA256:AES256-GCM-SHA384:AES256-SHA:AES256-SHA256:DES-CBC3-SHA:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-SHA:ECDHE-RSA-AES128-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-SHA:ECDHE-RSA-AES256-SHA384
```

Note that the list of ciphers is necessarily
restricted to a subset of ciphers supported by the
client (i.e. openssl(1)).

If you have a different version of openssl(1)
installed, you can use that via the '-o' flag.  In the
following example, /tmp/openssl supports a much
shorter list of ciphers:

```
$ cipherdiff -o /tmp/openssl www.yahoo.com
AES128-SHA:AES256-SHA:DES-CBC3-SHA
```

To list the ciphers supported by the remote server in
order of preference:

```
$ cipherdiff -p www.yahoo.com
ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES128-SHA256:ECDHE-RSA-AES256-SHA384:ECDHE-RSA-AES128-SHA:ECDHE-RSA-AES256-SHA:AES128-GCM-SHA256:AES256-GCM-SHA384:AES128-SHA256:AES256-SHA256:AES128-SHA:AES256-SHA:DES-CBC3-SHA
```

To list the ciphers _not_ supported by the remote
server, but available on the client side:

```
$ cipherdiff -u www.yahoo.com
CAMELLIA128-SHA:CAMELLIA256-SHA:DHE-DSS-AES128-GCM-SHA256:DHE-DSS-AES128-SHA:DHE-DSS-AES128-SHA256:DHE-DSS-AES256-GCM-SHA384:DHE-DSS-AES256-SHA:DHE-DSS-AES256-SHA256:DHE-DSS-CAMELLIA128-SHA:DHE-DSS-CAMELLIA256-SHA:DHE-DSS-SEED-SHA:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES128-SHA:DHE-RSA-AES128-SHA256:DHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-SHA:DHE-RSA-AES256-SHA256:DHE-RSA-CAMELLIA128-SHA:DHE-RSA-CAMELLIA256-SHA:DHE-RSA-SEED-SHA:ECDH-ECDSA-AES128-GCM-SHA256:ECDH-ECDSA-AES128-SHA:ECDH-ECDSA-AES128-SHA256:ECDH-ECDSA-AES256-GCM-SHA384:ECDH-ECDSA-AES256-SHA:ECDH-ECDSA-AES256-SHA384:ECDH-ECDSA-DES-CBC3-SHA:ECDH-ECDSA-RC4-SHA:ECDH-RSA-AES128-GCM-SHA256:ECDH-RSA-AES128-SHA:ECDH-RSA-AES128-SHA256:ECDH-RSA-AES256-GCM-SHA384:ECDH-RSA-AES256-SHA:ECDH-RSA-AES256-SHA384:ECDH-RSA-DES-CBC3-SHA:ECDH-RSA-RC4-SHA:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES128-SHA:ECDHE-ECDSA-AES128-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES256-SHA:ECDHE-ECDSA-AES256-SHA384:ECDHE-ECDSA-DES-CBC3-SHA:ECDHE-ECDSA-RC4-SHA:ECDHE-RSA-DES-CBC3-SHA:ECDHE-RSA-RC4-SHA:EDH-DSS-DES-CBC3-SHA:EDH-RSA-DES-CBC3-SHA:PSK-3DES-EDE-CBC-SHA:PSK-AES128-CBC-SHA:PSK-AES256-CBC-SHA:PSK-RC4-SHA:RC4-MD5:RC4-SHA:SEED-SHA:SRP-3DES-EDE-CBC-SHA:SRP-AES-128-CBC-SHA:SRP-AES-256-CBC-SHA:SRP-DSS-3DES-EDE-CBC-SHA:SRP-DSS-AES-128-CBC-SHA:SRP-DSS-AES-256-CBC-SHA:SRP-RSA-3DES-EDE-CBC-SHA:SRP-RSA-AES-128-CBC-SHA:SRP-RSA-AES-256-CBC-SHA
```

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

Supported by server, but not in input spec:
ECDHE-RSA-AES128-SHA256

Input spec and server preference differ.
Input spec:
ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-SHA384:RC4-MD5:ECDHE-RSA-AES128-SHA:ECDHE-RSA-AES256-SHA:AES128-GCM-SHA256:AES256-GCM-SHA384:AES256-SHA256:AES128-SHA256:AES128-SHA:AES256-SHA:DES-CBC3-SHA
===
Observed preference:
ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES128-SHA256:ECDHE-RSA-AES256-SHA384:ECDHE-RSA-AES128-SHA:ECDHE-RSA-AES256-SHA:AES128-GCM-SHA256:AES256-GCM-SHA384:AES128-SHA256:AES256-SHA256:AES128-SHA:AES256-SHA:DES-CBC3-SHA
```

You can also get the output marked up using terminal
color escape sequences using the '-c' flag:

Ciphers missing on the server but found in the spec
will be printed in blue, extra ciphers offered by
the server but not found in the spec in magenta, ciphers
that are deprioritized by the server compared to the
spec in red, and ciphers that are preferred by the
server over the spec in yellow:

![color output example](docs/colorexample.png)
