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

To list the ciphers supported in order of preference
by the remote server:

```
$ cipherdiff www.yahoo.com
AES128-SHA:AES256-SHA:DES-CBC3-SHA
```

Note that the list of ciphers is necessarily
restricted to a subset of ciphers supported by the
client (i.e. openssl(1)).

If you have a different version of openssl(1)
installed, you can use that via the '-o' flag:

```
$ cipherdiff -o /tmp/openssl www.yahoo.com
ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES128-SHA256:ECDHE-RSA-AES256-SHA384:ECDHE-RSA-AES128-SHA:ECDHE-RSA-AES256-SHA:AES128-GCM-SHA256:AES256-GCM-SHA384:AES128-SHA256:AES256-SHA256:AES128-SHA:AES256-SHA:DES-CBC3-SHA
```

If you have an existing cipher spec and want to verify
that the server follows it, you can pass it via the
'-s' flag:

```
$ cat /tmp/s
ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES128-SHA256:EXP-RC4-MD5:ECDHE-RSA-AES128-SHA:ECDHE-RSA-AES256-SHA384:ECDHE-RSA-AES256-SHA:DHE-RSA-AES128-SHA:DHE-RSA-AES256-SHA256:DHE-RSA-AES256-SHA:AES256-GCM-SHA384
$ cipherdiff -s $(cat /tmp/s) -p www.yahoo.com
Shared ciphers: AES128-GCM-SHA256:AES128-SHA:AES128-SHA256:AES256-GCM-SHA384:AES256-SHA:AES256-SHA256:DES-CBC3-SHA:ECDHE-RSA-AES128-SHA:ECDHE-RSA-AES128-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-SHA:ECDHE-RSA-AES256-SHA384

In input spec, but not supported by server: RC4-MD5

Supported by server, but not in input spec: ECDHE-RSA-AES128-GCM-SHA256

Input spec and server preference differ.
Input spec:
ECDHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES128-SHA256:ECDHE-RSA-AES256-SHA384:ECDHE-RSA-AES128-SHA:ECDHE-RSA-AES256-SHA:RC4-MD5:AES128-GCM-SHA256:AES256-GCM-SHA384:AES128-SHA256:AES256-SHA256:AES128-SHA:DES-CBC3-SHA:AES256-SHA
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
server over the spec in yellow.
