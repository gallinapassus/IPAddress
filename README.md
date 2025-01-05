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
│                      Operating system Version 15.2 (Build 24C101)                       │
├──────────────────────────────┬──────────────────────┬────────┬──────────────────────────┤
│                              │                      │  Test  │                          │
│                              │ Measured performance │  data  │                          │
│ IPAddress API                │  invocations / sec   │  type  │         Comment          │
├──────────────────────────────┼──────────────────────┼────────┼──────────────────────────┤
│ .init(_:_:_:_:cidr:)         │           83 755 384 │  ipv4  │ Randomized addresses     │
├──────────────────────────────┼──────────────────────┼────────┼──────────────────────────┤
│ .init(_:cidr:)               │           84 578 776 │  ipv4  │ Randomized addresses     │
├──────────────────────────────┼──────────────────────┼────────┼──────────────────────────┤
│ .init(_:_:_:_:_:_:_:_:cidr:) │           76 658 358 │  ipv6  │ Randomized addresses     │
├──────────────────────────────┼──────────────────────┼────────┼──────────────────────────┤
│                              │                      │        │ Randomized               │
│ .init?(bytes:cidr:)          │           21 879 997 │  ipv4  │ valid addresses          │
├──────────────────────────────┼──────────────────────┼────────┼──────────────────────────┤
│                              │                      │        │ Randomized               │
│ .init?(bytes:cidr:)          │           22 354 482 │  ipv6  │ valid addresses          │
├──────────────────────────────┼──────────────────────┼────────┼──────────────────────────┤
│                              │                      │        │ Randomized               │
│ .init?(data:cidr:)           │           13 448 021 │  ipv4  │ valid addresses          │
├──────────────────────────────┼──────────────────────┼────────┼──────────────────────────┤
│                              │                      │        │ Randomized               │
│ .init?(data:cidr:)           │           11 476 939 │  ipv6  │ valid addresses          │
├──────────────────────────────┼──────────────────────┼────────┼──────────────────────────┤
│                              │                      │  ipv4  │ Mix of strings resulting │
│ .init?(_:)                   │            2 001 876 │ & ipv6 │ failure / success        │
├──────────────────────────────┼──────────────────────┼────────┼──────────────────────────┤
│                              │                      │        │ Randomized               │
│ .init?(_:)                   │              478 237 │  ipv6  │ valid addresses          │
├──────────────────────────────┼──────────────────────┼────────┼──────────────────────────┤
│                              │                      │        │ Randomized               │
│ .init?(_:)                   │            1 312 511 │  ipv4  │ valid addresses          │
├──────────────────────────────┼──────────────────────┼────────┼──────────────────────────┤
│                              │                      │        │ Randomized addresses     │
│ .contains(other:)            │            2 167 272 │  ipv4  │ true 44.0%, false 56.0%  │
├──────────────────────────────┼──────────────────────┼────────┼──────────────────────────┤
│                              │                      │        │ Randomized addresses     │
│ .contains(other:)            │            1 178 589 │  ipv6  │ true 54.0%, false 46.0%  │
├──────────────────────────────┼──────────────────────┼────────┼──────────────────────────┤
│                              │                      │        │ Randomized               │
│ .advanced(by:clamped:)       │           76 398 568 │  ipv4  │ addresses, not clamped   │
├──────────────────────────────┼──────────────────────┼────────┼──────────────────────────┤
│                              │                      │        │ Randomized               │
│ .advanced(by:clamped:)       │           69 874 398 │  ipv6  │ addresses, not clamped   │
├──────────────────────────────┼──────────────────────┼────────┼──────────────────────────┤
│                              │                      │        │ Randomized               │
│ .next()                      │          141 763 868 │  ipv4  │ addresses, clamped       │
├──────────────────────────────┼──────────────────────┼────────┼──────────────────────────┤
│                              │                      │        │ Randomized               │
│ .next()                      │          138 508 446 │  ipv6  │ addresses, clamped       │
├──────────────────────────────┼──────────────────────┼────────┼──────────────────────────┤
│ .description                 │            3 745 396 │  ipv4  │ Randomized addresses     │
├──────────────────────────────┼──────────────────────┼────────┼──────────────────────────┤
│ .description                 │            1 390 889 │  ipv6  │ Randomized addresses     │
├──────────────────────────────┼──────────────────────┼────────┼──────────────────────────┤
│ .compactDescription          │            1 498 103 │  ipv6  │ Randomized addresses     │
╰──────────────────────────────┴──────────────────────┴────────┴──────────────────────────╯
```
