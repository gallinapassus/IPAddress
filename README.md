# IPAddress

A concrete type capable of encapsulating both ipv4 and ipv6 addresses.

# IPAddressIterator

An iterator over the elements of type `IPAddress`.

# IPAddressSequence

A type providing sequential, iterated access to `IPAddress` elements.

# Reference performance
```
╭─────────────────────────────────────────────────────────────────────────────────────────╮
│                         Performance test summary for Operating                          │
│  system Version 12.6.1 (Build 21G217), Apple M1 Max, 10 processors, 64.0 GiB of memory  │
├──────────────────────────────┬──────────────────────┬────────┬──────────────────────────┤
│                              │                      │  Test  │                          │
│                              │ Measured performance │  data  │                          │
│ IPAddress API                │  invocations / sec   │  type  │         Comment          │
├──────────────────────────────┼──────────────────────┼────────┼──────────────────────────┤
│ .init(_:_:_:_:cidr:)         │           15 272 304 │  ipv4  │ Randomized addresses     │
├──────────────────────────────┼──────────────────────┼────────┼──────────────────────────┤
│ .init(_:cidr:)               │           15 280 955 │  ipv4  │ Randomized addresses     │
├──────────────────────────────┼──────────────────────┼────────┼──────────────────────────┤
│ .init(_:_:_:_:_:_:_:_:cidr:) │           14 779 299 │  ipv6  │ Randomized addresses     │
├──────────────────────────────┼──────────────────────┼────────┼──────────────────────────┤
│                              │                      │        │ Randomized               │
│ .init?(bytes:cidr:)          │           12 915 493 │  ipv4  │ valid addresses          │
├──────────────────────────────┼──────────────────────┼────────┼──────────────────────────┤
│                              │                      │        │ Randomized               │
│ .init?(bytes:cidr:)          │           12 786 868 │  ipv6  │ valid addresses          │
├──────────────────────────────┼──────────────────────┼────────┼──────────────────────────┤
│                              │                      │        │ Randomized               │
│ .init?(data:cidr:)           │            8 246 477 │  ipv4  │ valid addresses          │
├──────────────────────────────┼──────────────────────┼────────┼──────────────────────────┤
│                              │                      │        │ Randomized               │
│ .init?(data:cidr:)           │            7 555 235 │  ipv6  │ valid addresses          │
├──────────────────────────────┼──────────────────────┼────────┼──────────────────────────┤
│                              │                      │  ipv4  │ Mix of strings resulting │
│ .init?(_:)                   │              100 386 │ & ipv6 │ failure / success        │
├──────────────────────────────┼──────────────────────┼────────┼──────────────────────────┤
│                              │                      │  ipv4  │ Mix of strings resulting │
│ .init?(string:)              │            1 781 097 │ & ipv6 │ failure / success        │
├──────────────────────────────┼──────────────────────┼────────┼──────────────────────────┤
│                              │                      │        │ Randomized               │
│ .init?(string:)              │              484 763 │  ipv6  │ valid addresses          │
├──────────────────────────────┼──────────────────────┼────────┼──────────────────────────┤
│                              │                      │        │ Randomized addresses     │
│ .contains(other:)            │            1 866 253 │  ipv4  │ true 44.0%, false 56.0%  │
├──────────────────────────────┼──────────────────────┼────────┼──────────────────────────┤
│                              │                      │        │ Randomized addresses     │
│ .contains(other:)            │            1 146 219 │  ipv6  │ true 53.0%, false 47.0%  │
├──────────────────────────────┼──────────────────────┼────────┼──────────────────────────┤
│                              │                      │        │ Randomized               │
│ .advanced(by:clamped:)       │           13 574 120 │  ipv4  │ addresses, not clamped   │
├──────────────────────────────┼──────────────────────┼────────┼──────────────────────────┤
│                              │                      │        │ Randomized               │
│ .advanced(by:clamped:)       │           20 340 028 │  ipv6  │ addresses, not clamped   │
├──────────────────────────────┼──────────────────────┼────────┼──────────────────────────┤
│                              │                      │        │ Randomized               │
│ .next()                      │           25 150 836 │  ipv4  │ addresses, clamped       │
├──────────────────────────────┼──────────────────────┼────────┼──────────────────────────┤
│                              │                      │        │ Randomized               │
│ .next()                      │           21 669 149 │  ipv6  │ addresses, clamped       │
├──────────────────────────────┼──────────────────────┼────────┼──────────────────────────┤
│ .description                 │            5 260 751 │  ipv4  │ Randomized addresses     │
├──────────────────────────────┼──────────────────────┼────────┼──────────────────────────┤
│ .description                 │            1 783 744 │  ipv6  │ Randomized addresses     │
├──────────────────────────────┼──────────────────────┼────────┼──────────────────────────┤
│ .compactDescription          │            1 581 709 │  ipv6  │ Randomized addresses     │
╰──────────────────────────────┴──────────────────────┴────────┴──────────────────────────╯
```
