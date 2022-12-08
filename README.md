[![Tests](https://github.com/gallinapassus/IPAddress/actions/workflows/ipaddress-ci.yml/badge.svg)](https://github.com/gallinapassus/IPAddress/actions/workflows/ipaddress-ci.yml)

# IPAddress

A concrete type capable of encapsulating both ipv4 and ipv6 addresses.

# IPAddressIterator

An iterator over the elements of type `IPAddress`.

# IPAddressSequence

A type providing sequential, iterated access to `IPAddress` elements.

# Reference performance
```
╭─────────────────────────────────────────────────────────────────────────────────────────╮
│                              Performance test summary for                               │
│                     Apple M1 Max, 10 processors, 64.0 GiB of memory                     │
│                     Operating system Version 12.6.1 (Build 21G217)                      │
├──────────────────────────────┬──────────────────────┬────────┬──────────────────────────┤
│                              │                      │  Test  │                          │
│                              │ Measured performance │  data  │                          │
│ IPAddress API                │  invocations / sec   │  type  │         Comment          │
├──────────────────────────────┼──────────────────────┼────────┼──────────────────────────┤
│ .init(_:_:_:_:cidr:)         │           15 115 265 │  ipv4  │ Randomized addresses     │
├──────────────────────────────┼──────────────────────┼────────┼──────────────────────────┤
│ .init(_:cidr:)               │           15 308 520 │  ipv4  │ Randomized addresses     │
├──────────────────────────────┼──────────────────────┼────────┼──────────────────────────┤
│ .init(_:_:_:_:_:_:_:_:cidr:) │           13 921 826 │  ipv6  │ Randomized addresses     │
├──────────────────────────────┼──────────────────────┼────────┼──────────────────────────┤
│                              │                      │        │ Randomized               │
│ .init?(bytes:cidr:)          │           12 907 119 │  ipv4  │ valid addresses          │
├──────────────────────────────┼──────────────────────┼────────┼──────────────────────────┤
│                              │                      │        │ Randomized               │
│ .init?(bytes:cidr:)          │           12 836 030 │  ipv6  │ valid addresses          │
├──────────────────────────────┼──────────────────────┼────────┼──────────────────────────┤
│                              │                      │        │ Randomized               │
│ .init?(data:cidr:)           │            8 232 379 │  ipv4  │ valid addresses          │
├──────────────────────────────┼──────────────────────┼────────┼──────────────────────────┤
│                              │                      │        │ Randomized               │
│ .init?(data:cidr:)           │            7 533 066 │  ipv6  │ valid addresses          │
├──────────────────────────────┼──────────────────────┼────────┼──────────────────────────┤
│                              │                      │  ipv4  │ Mix of strings resulting │
│ .init?(_:)                   │            1 792 171 │ & ipv6 │ failure / success        │
├──────────────────────────────┼──────────────────────┼────────┼──────────────────────────┤
│                              │                      │        │ Randomized               │
│ .init?(_:)                   │              489 545 │  ipv6  │ valid addresses          │
├──────────────────────────────┼──────────────────────┼────────┼──────────────────────────┤
│                              │                      │        │ Randomized               │
│ .init?(_:)                   │            1 140 172 │  ipv4  │ valid addresses          │
├──────────────────────────────┼──────────────────────┼────────┼──────────────────────────┤
│                              │                      │        │ Randomized addresses     │
│ .contains(other:)            │            1 861 306 │  ipv4  │ true 44.0%, false 56.0%  │
├──────────────────────────────┼──────────────────────┼────────┼──────────────────────────┤
│                              │                      │        │ Randomized addresses     │
│ .contains(other:)            │            1 144 732 │  ipv6  │ true 54.0%, false 46.0%  │
├──────────────────────────────┼──────────────────────┼────────┼──────────────────────────┤
│                              │                      │        │ Randomized               │
│ .advanced(by:clamped:)       │           12 705 592 │  ipv4  │ addresses, not clamped   │
├──────────────────────────────┼──────────────────────┼────────┼──────────────────────────┤
│                              │                      │        │ Randomized               │
│ .advanced(by:clamped:)       │           18 817 378 │  ipv6  │ addresses, not clamped   │
├──────────────────────────────┼──────────────────────┼────────┼──────────────────────────┤
│                              │                      │        │ Randomized               │
│ .next()                      │           25 021 817 │  ipv4  │ addresses, clamped       │
├──────────────────────────────┼──────────────────────┼────────┼──────────────────────────┤
│                              │                      │        │ Randomized               │
│ .next()                      │           21 667 485 │  ipv6  │ addresses, clamped       │
├──────────────────────────────┼──────────────────────┼────────┼──────────────────────────┤
│ .description                 │            5 291 177 │  ipv4  │ Randomized addresses     │
├──────────────────────────────┼──────────────────────┼────────┼──────────────────────────┤
│ .description                 │            1 783 336 │  ipv6  │ Randomized addresses     │
├──────────────────────────────┼──────────────────────┼────────┼──────────────────────────┤
│ .compactDescription          │            1 632 285 │  ipv6  │ Randomized addresses     │
╰──────────────────────────────┴──────────────────────┴────────┴──────────────────────────╯
```
