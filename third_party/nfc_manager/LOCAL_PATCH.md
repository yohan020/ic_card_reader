# Local Android patch

Base package: `nfc_manager 4.2.1`
Upstream: <https://github.com/okadan/flutter-nfc-manager>

Samsung Android devices may broadcast the vendor-specific NFC adapter state
value `5`. The upstream Android receiver passes every value to a mapper that
throws for values outside Android's public `STATE_OFF`, `STATE_TURNING_ON`,
`STATE_ON`, and `STATE_TURNING_OFF` constants. Because the exception is thrown
inside a native `BroadcastReceiver`, it terminates the whole application before
Dart can handle it.

This local patch maps unknown values to the plugin's `OFF` state. On the tested
Samsung device, value `5` is broadcast when switching from NFC basic mode to
card-only mode. Reader mode is unavailable in card-only mode, so forwarding an
`OFF` state lets Flutter stop the scan and show a basic-mode instruction instead
of crashing or waiting forever. Public Android adapter states continue to be
delivered to Dart unchanged.
