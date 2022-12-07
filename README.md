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
│                     Operating system Version 12.6.1 (Build 21G217)                      │
│                     Apple M1 Max, 10 processors, 64.0 GiB of memory                     │
├──────────────────────────────┬──────────────────────┬────────┬──────────────────────────┤
│                              │                      │  Test  │                          │
│                              │ Measured performance │  data  │                          │
│ IPAddress API                │  invocations / sec   │  type  │         Comment          │
├──────────────────────────────┼──────────────────────┼────────┼──────────────────────────┤
│ .init(_:_:_:_:cidr:)         │           13 877 235 │  ipv4  │ Randomized addresses     │
├──────────────────────────────┼──────────────────────┼────────┼──────────────────────────┤
│ .init(_:cidr:)               │           14 049 354 │  ipv4  │ Randomized addresses     │
├──────────────────────────────┼──────────────────────┼────────┼──────────────────────────┤
│ .init(_:_:_:_:_:_:_:_:cidr:) │           13 051 990 │  ipv6  │ Randomized addresses     │
├──────────────────────────────┼──────────────────────┼────────┼──────────────────────────┤
│                              │                      │        │ Randomized               │
│ .init?(bytes:cidr:)          │           12 288 680 │  ipv4  │ valid addresses          │
├──────────────────────────────┼──────────────────────┼────────┼──────────────────────────┤
│                              │                      │        │ Randomized               │
│ .init?(bytes:cidr:)          │           12 703 541 │  ipv6  │ valid addresses          │
├──────────────────────────────┼──────────────────────┼────────┼──────────────────────────┤
│                              │                      │        │ Randomized               │
│ .init?(data:cidr:)           │            7 623 524 │  ipv4  │ valid addresses          │
├──────────────────────────────┼──────────────────────┼────────┼──────────────────────────┤
│                              │                      │        │ Randomized               │
│ .init?(data:cidr:)           │            6 939 168 │  ipv6  │ valid addresses          │
├──────────────────────────────┼──────────────────────┼────────┼──────────────────────────┤
│                              │                      │  ipv4  │ Mix of strings resulting │
│ .init?(_:)                   │            1 644 526 │ & ipv6 │ failure / success        │
├──────────────────────────────┼──────────────────────┼────────┼──────────────────────────┤
│                              │                      │        │ Randomized               │
│ .init?(_:)                   │              450 048 │  ipv6  │ valid addresses          │
├──────────────────────────────┼──────────────────────┼────────┼──────────────────────────┤
│                              │                      │        │ Randomized               │
│ .init?(_:)                   │            1 056 989 │  ipv4  │ valid addresses          │
├──────────────────────────────┼──────────────────────┼────────┼──────────────────────────┤
│                              │                      │        │ Randomized addresses     │
│ .contains(other:)            │            1 689 741 │  ipv4  │ true 44.0%, false 56.0%  │
├──────────────────────────────┼──────────────────────┼────────┼──────────────────────────┤
│                              │                      │        │ Randomized addresses     │
│ .contains(other:)            │            1 044 200 │  ipv6  │ true 53.0%, false 47.0%  │
├──────────────────────────────┼──────────────────────┼────────┼──────────────────────────┤
│                              │                      │        │ Randomized               │
│ .advanced(by:clamped:)       │           12 532 094 │  ipv4  │ addresses, not clamped   │
├──────────────────────────────┼──────────────────────┼────────┼──────────────────────────┤
│                              │                      │        │ Randomized               │
│ .advanced(by:clamped:)       │           18 616 708 │  ipv6  │ addresses, not clamped   │
├──────────────────────────────┼──────────────────────┼────────┼──────────────────────────┤
│                              │                      │        │ Randomized               │
│ .next()                      │           23 641 498 │  ipv4  │ addresses, clamped       │
├──────────────────────────────┼──────────────────────┼────────┼──────────────────────────┤
│                              │                      │        │ Randomized               │
│ .next()                      │           20 087 964 │  ipv6  │ addresses, clamped       │
├──────────────────────────────┼──────────────────────┼────────┼──────────────────────────┤
│ .description                 │            4 841 680 │  ipv4  │ Randomized addresses     │
├──────────────────────────────┼──────────────────────┼────────┼──────────────────────────┤
│ .description                 │            1 641 927 │  ipv6  │ Randomized addresses     │
├──────────────────────────────┼──────────────────────┼────────┼──────────────────────────┤
│ .compactDescription          │            1 446 655 │  ipv6  │ Randomized addresses     │
╰──────────────────────────────┴──────────────────────┴────────┴──────────────────────────╯
```
