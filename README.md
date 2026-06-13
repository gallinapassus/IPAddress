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
```
╭─────────────────────────────────────────────────────────────────────────────────────────╮
│                              Performance test summary for                               │
│       Intel(R) Core(TM) i7-6920HQ CPU @ 2.90GHz, 8 processors, 16.0 GiB of memory       │
│                     Operating system Version 12.7.6 (Build 21H1320)                     │
├──────────────────────────────┬──────────────────────┬────────┬──────────────────────────┤
│                              │                      │  Test  │                          │
│                              │ Measured performance │  data  │                          │
│ IPAddress API                │   invocations / sec  │  type  │         Comment          │
├──────────────────────────────┼──────────────────────┼────────┼──────────────────────────┤
│ .init(_:_:_:_:cidr:)         │            1 789 697 │  ipv4  │ Randomized addresses     │
├──────────────────────────────┼──────────────────────┼────────┼──────────────────────────┤
│ .init(_:cidr:)               │           11 397 271 │  ipv4  │ Randomized addresses     │
├──────────────────────────────┼──────────────────────┼────────┼──────────────────────────┤
│ .init(_:_:_:_:_:_:_:_:cidr:) │              997 658 │  ipv6  │ Randomized addresses     │
├──────────────────────────────┼──────────────────────┼────────┼──────────────────────────┤
│                              │                      │        │ Randomized valid         │
│ .init?(bytes:cidr:)          │            1 473 030 │  ipv4  │ addresses                │
├──────────────────────────────┼──────────────────────┼────────┼──────────────────────────┤
│                              │                      │        │ Randomized valid         │
│ .init?(bytes:cidr:)          │              403 167 │  ipv6  │ addresses                │
├──────────────────────────────┼──────────────────────┼────────┼──────────────────────────┤
│                              │                      │        │ Randomized valid         │
│ .init?(data:cidr:)           │            1 006 048 │  ipv4  │ addresses                │
├──────────────────────────────┼──────────────────────┼────────┼──────────────────────────┤
│                              │                      │        │ Randomized valid         │
│ .init?(data:cidr:)           │              355 769 │  ipv6  │ addresses                │
├──────────────────────────────┼──────────────────────┼────────┼──────────────────────────┤
│                              │                      │ ipv4 & │ Mix of strings resulting │
│ .init?(_:)                   │              105 665 │  ipv6  │ failure / success        │
├──────────────────────────────┼──────────────────────┼────────┼──────────────────────────┤
│                              │                      │        │ Randomized valid         │
│ .init?(_:)                   │               30 033 │  ipv6  │ addresses                │
├──────────────────────────────┼──────────────────────┼────────┼──────────────────────────┤
│                              │                      │        │ Randomized valid         │
│ .init?(_:)                   │               45 339 │  ipv4  │ addresses                │
├──────────────────────────────┼──────────────────────┼────────┼──────────────────────────┤
│                              │                      │        │ Randomized addresses     │
│ .contains(other:)            │               53 166 │  ipv4  │ true 44.0%, false 56.0%  │
├──────────────────────────────┼──────────────────────┼────────┼──────────────────────────┤
│                              │                      │        │ Randomized addresses     │
│ .contains(other:)            │                9 863 │  ipv6  │ true 54.0%, false 46.0%  │
├──────────────────────────────┼──────────────────────┼────────┼──────────────────────────┤
│                              │                      │        │ Randomized addresses,    │
│ .advanced(by:clamped:)       │            2 084 498 │  ipv4  │ not clamped              │
├──────────────────────────────┼──────────────────────┼────────┼──────────────────────────┤
│                              │                      │        │ Randomized addresses,    │
│ .advanced(by:clamped:)       │            2 698 376 │  ipv6  │ not clamped              │
├──────────────────────────────┼──────────────────────┼────────┼──────────────────────────┤
│                              │                      │        │ Randomized addresses,    │
│ .next()                      │           10 381 440 │  ipv4  │ clamped                  │
├──────────────────────────────┼──────────────────────┼────────┼──────────────────────────┤
│                              │                      │        │ Randomized addresses,    │
│ .next()                      │            9 823 609 │  ipv6  │ clamped                  │
├──────────────────────────────┼──────────────────────┼────────┼──────────────────────────┤
│ .description                 │              864 419 │  ipv4  │ Randomized addresses     │
├──────────────────────────────┼──────────────────────┼────────┼──────────────────────────┤
│ .description                 │              331 202 │  ipv6  │ Randomized addresses     │
├──────────────────────────────┼──────────────────────┼────────┼──────────────────────────┤
│ .compactDescription          │              107 587 │  ipv6  │ Randomized addresses     │
╰──────────────────────────────┴──────────────────────┴────────┴──────────────────────────╯
```
