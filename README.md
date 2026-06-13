[![Tests](https://github.com/gallinapassus/IPAddress/actions/workflows/ipaddress-ci.yml/badge.svg)](https://github.com/gallinapassus/IPAddress/actions/workflows/ipaddress-ci.yml)

# IPAddress

A concrete type capable of encapsulating both ipv4 and ipv6 addresses.

# IPAddressIterator

An iterator over the elements of type `IPAddress`.

# IPAddressSequence

A type providing sequential, iterated access to `IPAddress` elements.

# IPAddressAndPort

A concrete type for storing IPAddress, port and (transport layer) ip-protocol (tcp or udp).

# Reference performance

Performance reference results are generated **locally** by running the
performance test and are written to the [`performance/`](performance/) folder —
one file per measured system configuration and build mode (e.g.
`perf-<config-hash>-release.txt`, with a matching `.json` sidecar). Each report
records the build configuration (debug/release), Swift version, hardware/OS
spec and a timestamp.

The `performance/` folder is **git-ignored**, so checking in a result is a
deliberate action:

```sh
git add -f performance/perf-<config-hash>-release.txt
```

Generate / refresh a result for the current machine:

```sh
# release build (recommended for reference numbers)
swift test -c release --filter PerformanceTests/test_run_all_perf_tests

# debug build (build mode is recorded in the report)
swift test --filter PerformanceTests/test_run_all_perf_tests
```

The numbers are rendered in the same bordered table format as before; the test
prints the exact output file paths when it finishes.
