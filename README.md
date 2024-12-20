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
│ .init(_:_:_:_:cidr:)         │           20 906 416 │  ipv4  │ Randomized addresses     │
├──────────────────────────────┼──────────────────────┼────────┼──────────────────────────┤
│ .init(_:cidr:)               │           21 960 770 │  ipv4  │ Randomized addresses     │
├──────────────────────────────┼──────────────────────┼────────┼──────────────────────────┤
│ .init(_:_:_:_:_:_:_:_:cidr:) │           19 098 646 │  ipv6  │ Randomized addresses     │
├──────────────────────────────┼──────────────────────┼────────┼──────────────────────────┤
│                              │                      │        │ Randomized               │
│ .init?(bytes:cidr:)          │           13 215 754 │  ipv4  │ valid addresses          │
├──────────────────────────────┼──────────────────────┼────────┼──────────────────────────┤
│                              │                      │        │ Randomized               │
│ .init?(bytes:cidr:)          │           13 166 898 │  ipv6  │ valid addresses          │
├──────────────────────────────┼──────────────────────┼────────┼──────────────────────────┤
│                              │                      │        │ Randomized               │
│ .init?(data:cidr:)           │            9 529 239 │  ipv4  │ valid addresses          │
├──────────────────────────────┼──────────────────────┼────────┼──────────────────────────┤
│                              │                      │        │ Randomized               │
│ .init?(data:cidr:)           │            8 623 778 │  ipv6  │ valid addresses          │
├──────────────────────────────┼──────────────────────┼────────┼──────────────────────────┤
│                              │                      │  ipv4  │ Mix of strings resulting │
│ .init?(_:)                   │            1 886 427 │ & ipv6 │ failure / success        │
├──────────────────────────────┼──────────────────────┼────────┼──────────────────────────┤
│                              │                      │        │ Randomized               │
│ .init?(_:)                   │              457 597 │  ipv6  │ valid addresses          │
├──────────────────────────────┼──────────────────────┼────────┼──────────────────────────┤
│                              │                      │        │ Randomized               │
│ .init?(_:)                   │            1 238 937 │  ipv4  │ valid addresses          │
├──────────────────────────────┼──────────────────────┼────────┼──────────────────────────┤
│                              │                      │        │ Randomized addresses     │
│ .contains(other:)            │            1 807 439 │  ipv4  │ true 44.0%, false 56.0%  │
├──────────────────────────────┼──────────────────────┼────────┼──────────────────────────┤
│                              │                      │        │ Randomized addresses     │
│ .contains(other:)            │            1 172 140 │  ipv6  │ true 54.0%, false 46.0%  │
├──────────────────────────────┼──────────────────────┼────────┼──────────────────────────┤
│                              │                      │        │ Randomized               │
│ .advanced(by:clamped:)       │           10 351 481 │  ipv4  │ addresses, not clamped   │
├──────────────────────────────┼──────────────────────┼────────┼──────────────────────────┤
│                              │                      │        │ Randomized               │
│ .advanced(by:clamped:)       │           15 311 939 │  ipv6  │ addresses, not clamped   │
├──────────────────────────────┼──────────────────────┼────────┼──────────────────────────┤
│                              │                      │        │ Randomized               │
│ .next()                      │           23 901 926 │  ipv4  │ addresses, clamped       │
├──────────────────────────────┼──────────────────────┼────────┼──────────────────────────┤
│                              │                      │        │ Randomized               │
│ .next()                      │           23 130 792 │  ipv6  │ addresses, clamped       │
├──────────────────────────────┼──────────────────────┼────────┼──────────────────────────┤
│ .description                 │            4 145 564 │  ipv4  │ Randomized addresses     │
├──────────────────────────────┼──────────────────────┼────────┼──────────────────────────┤
│ .description                 │            1 583 799 │  ipv6  │ Randomized addresses     │
├──────────────────────────────┼──────────────────────┼────────┼──────────────────────────┤
│ .compactDescription          │            1 544 635 │  ipv6  │ Randomized addresses     │
╰──────────────────────────────┴──────────────────────┴────────┴──────────────────────────╯
```
