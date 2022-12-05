import Foundation

internal func parser(_ str:String, options:IPAddress.ParsingOptions = IPAddress.ParsingOptions()) -> IPAddress? {
    let iii = str.indices
    var digitStack:[UInt8] = []
    var u16Stack:[UInt16] = []
    var consecutiveSeparatorCount:Int = 0
    let maskAddressType:UInt16 =    0b0000_0000_0000_0011
    let maskZeroBit:UInt16 =        0b0000_0000_0000_0100
    let maskInsertionPoint:UInt16 = 0b0000_0000_1111_0000
    let maskCidr:UInt16 =           0b1111_1111_0000_0000
    
    var bm:UInt16 = maskInsertionPoint | maskCidr
    if options.contains(.ipv4Only) {
        bm |= IPAddress.IPAddrType.v4.rawValue
    }
    else if options.contains(.ipv6Only) {
        bm |= IPAddress.IPAddrType.v6.rawValue
    }
    else {
        bm |= maskAddressType
    }
    //     ┌─────────────── cidr
    // ┌───┴───┐ ┌──┬────── insertion point
    // 0000.0000.0000.0000
    //                ││└┴─ addressType
    //                │└─── zeroBit
    //                └──── reserved for future use

    for i in iii {
        guard let hd = str[i].asciiValue, hd > 45, hd < 103 else {
            // invalid character
            return nil
        }
        // Colon ':'
        if hd == 58 {
            // Set zeroBit to false
            bm &= ~maskZeroBit
            if (bm & maskAddressType) == maskAddressType {
                // Set addressType to ipv6
                bm = (bm & ~maskAddressType) | IPAddress.IPAddrType.v6.rawValue
            }
            else if (bm & maskAddressType) != IPAddress.IPAddrType.v6.rawValue {
                // address type was earlier "locked" to ipv4
                return nil
            }
            // Check for ipv6 digit overflow
            guard digitStack.count < 5 else {
                return nil // too many digits for ipv6
            }
            // Set the u16 value
            var u16:UInt16 = 0
            for digit in digitStack {
                u16 = (u16 << 4) + UInt16(digit)
            }
            // Increment the consecutive separator counter
            consecutiveSeparatorCount += 1
            // Check if we have '::'
            if consecutiveSeparatorCount == 2 {
                // Have we already seen '::' before?
                guard (bm & maskInsertionPoint) == maskInsertionPoint else {
                    return nil // Yes, this is now a subsequent '::', only one '::' is allowed
                }
                if options.contains(.noZeroSupression) {
                    // zero suppression not allowed
                    return nil
                }
                // Save the insertion point
                bm = (bm & ~maskInsertionPoint) | (UInt16(u16Stack.count) << 4)
            }
            // Check if we have ':::' (or more)
            else if consecutiveSeparatorCount > 2 {
                // More than two colons are not allowed
                return nil
            }
            // Check if we have a single ':' at the end
            if i == iii.index(before: str.endIndex), consecutiveSeparatorCount != 2 {
                // Yes, address ends with single ':'. Single ':' at the end is not allowed.
                return nil
            }
            // Reset the digit stack, keep capacity
            digitStack.removeAll(keepingCapacity: true)
            // append segment value
            u16Stack.append(u16)
        }
        // Dot '.'
        else if hd == 46 {
            // Set zeroBit to false
            bm &= ~maskZeroBit
            // Set addressType to ipv4
            if (bm & maskAddressType) == maskAddressType {
                // Set addressType to ipv4
                bm = (bm & ~maskAddressType) | IPAddress.IPAddrType.v4.rawValue
            }
            else if (bm & maskAddressType) != IPAddress.IPAddrType.v4.rawValue {
                // address type was earlier "locked" to ipv6
                return nil
            }
            // Check for ipv4 digit overflow
            guard digitStack.count < 4 else {
                return nil // too many digits for ipv4
            }
            // Set the u16 value
            var u16:UInt16 = 0
            for (i,hd) in digitStack.reversed().enumerated() {
                var p:UInt16 = 1
                for _ in 0..<i {
                    p = p * 10
                }
                u16 += (p * UInt16(hd))
            }
            // Check that the ipv4 segment value is 0-255
            guard u16 < 256 else {
                // ipv4 segement overflow
                return nil
            }
            // Increment the consecutive separator counter
            consecutiveSeparatorCount += 1
            // Check if we have '..' (or more)
            guard consecutiveSeparatorCount < 2 else {
                // We have more than one consecutive colons, this is not allowed for ipv4 addresses
                return nil
            }
            // Reset the digit stack, keep capacity
            digitStack.removeAll(keepingCapacity: true)
            // append segment value
            u16Stack.append(u16)
        }
        // Slash '/'
        else if hd == 47 {
            // Make sure (ipv4 or ipv6) address part ends with digit segment
            // or with '::'
            guard consecutiveSeparatorCount == 0 || consecutiveSeparatorCount == 2 else {
                // Invalid address format, a well formed digit segment or '::' must precede cidr
                return nil
            }
            // Convert the cidr value from String to UInt8
            guard let c = UInt8(str[iii.index(after: i)...]) else {
                // Invalid cidr format
                return nil
            }
            // Set the cidr value
            bm = (bm & ~maskCidr) | UInt16(c) << 8
            // We're done here, break out and ignore the rest of the string
            break
        }
        // Digits '0 - 9'
        else if hd < 58 {
            // Check if we have a single separator in front of the first digit segment
            // ipv6 address :1234...
            //              └┴─ must fail
            // ipv6 address ::1234...
            //              └─┴─ must succeed
            // ipv6 address 1234:1234...
            //                  └┴─ must succeed
            // ipv4 address .168.5.4
            //              └┴─ must fail
            guard (i == iii.index(after: iii.startIndex) && consecutiveSeparatorCount == 1) == false else {
                // Yes, single separator in front of digit(s), not allowed
                return nil
            }
            if options.contains(.noLeadingZeros) {
                // Check if we have a leading zero
                guard (bm & maskZeroBit) == 0 else {
                    // Previous digit was zero and options has noLeadingZeros set, fail
                    return nil
                }
                // Set zeroBit accordingly
                bm = (hd == 48 && digitStack.count == 0) ? (bm | maskZeroBit) : (bm & ~maskZeroBit)
            }
            // append digit value
            digitStack.append(hd - 48)
            // reset consecutive separator count
            consecutiveSeparatorCount = 0
        }
        // a-f
        else if hd > 96 {
            // :abcd must fail
            if i == iii.index(after: iii.startIndex), consecutiveSeparatorCount == 1 {
                return nil
            }
            if (bm & maskZeroBit) > 0 {
                return nil
            }
            // append digit value
            digitStack.append(hd - 87)
            // set address type
            if (bm & maskAddressType) == maskAddressType {
                // Set addressType to ipv6
                bm = (bm & ~maskAddressType) | IPAddress.IPAddrType.v6.rawValue
            }
            else if (bm & maskAddressType) != IPAddress.IPAddrType.v6.rawValue {
                // address type was earlier "locked" to ipv4
                return nil
            }
            // reset consecutive separator count
            consecutiveSeparatorCount = 0
        }
        // A-F
        else if (65...70).contains(hd), options.contains(.noUppercase) == false {
            // :ABCD must fail
            if i == iii.index(after: iii.startIndex), consecutiveSeparatorCount == 1 {
                //print("invalid format", #line)
                return nil
            }
            if (bm & maskZeroBit) > 0 {
                return nil
            }
            // append digit value
            digitStack.append(hd - 55)
            // set address type
            if (bm & maskAddressType) == maskAddressType {
                // Set addressType to ipv6
                bm = (bm & ~maskAddressType) | IPAddress.IPAddrType.v6.rawValue
            }
            else if (bm & maskAddressType) != IPAddress.IPAddrType.v6.rawValue {
                // address type was earlier "locked" to ipv4
                return nil
            }
            // reset consecutive separator count
            consecutiveSeparatorCount = 0
        }
        else {
            // invalid character
            return nil
        }
    }
    
    // process remaining last segment
    if (bm & maskAddressType) == IPAddress.IPAddrType.v4.rawValue {
        
        // Check for digit and segment overflow
        guard digitStack.isEmpty == false, digitStack.count < 4, u16Stack.count < 4 else {
            return nil
        }
        // Set address segment values
        var u16:UInt16 = 0
        var p:UInt16 = 1
        for hd in digitStack.reversed() {
            u16 += (p * UInt16(hd))
            p *= 10
        }
        // Check for ipv4 segment value overflow
        guard u16 < 256 else {
            return nil
        }
        u16Stack.append(u16)
        
        // Do we have all required 4 segments of an ipv4 address
        guard u16Stack.count == 4 else {
            return nil
        }
        // Map values to UInt8
        let u8 = u16Stack.prefix(4).map({ UInt8($0) })
        // Initialize ipv4 address
        let cidr = (bm & maskCidr) == maskCidr ?
        IPAddress.validV4CIDRRange.upperBound
        :
        Int((bm & maskCidr) >> 8)
        return IPAddress(bytes: u8, cidr: cidr)
    }
    else if (bm & maskAddressType) == IPAddress.IPAddrType.v6.rawValue {
        
        // Check for digit and segment overflow
        guard (digitStack.isEmpty == false || bm & maskInsertionPoint != maskInsertionPoint), digitStack.count < 5, u16Stack.count < 8 else {
            return nil
        }
        // Set address segment values
        var u16:UInt16 = 0
        for hd in digitStack {
            u16 = (u16 << 4) + UInt16(hd)
        }
        u16Stack.append(u16)
        
        // Do we have all required 8 segments of an ipv4 address
        let cidr = (bm & maskCidr) == maskCidr ?
        IPAddress.validV6CIDRRange.upperBound
        :
        Int((bm & maskCidr) >> 8)
        guard u16Stack.count == 8 else {
            // Was there a wildcard '::'
            guard (bm & maskInsertionPoint) != maskInsertionPoint else {
                return nil // No wildcard '::' and we don't have enough segments
            }
            // Insertion elements
            let insert = Array(repeating: UInt16(0), count: Swift.max(0, 8 - u16Stack.count))
            // Insert
            u16Stack.insert(contentsOf: insert, at: Int((bm & maskInsertionPoint) >> 4))
            // Initialize ipv6 address
            return IPAddress(u16Stack[0], u16Stack[1], u16Stack[2], u16Stack[3], u16Stack[4], u16Stack[5], u16Stack[6], u16Stack[7], cidr: Int(cidr))
        }
        // Initialize ipv6 address
        return IPAddress(u16Stack[0], u16Stack[1], u16Stack[2], u16Stack[3], u16Stack[4], u16Stack[5], u16Stack[6], u16Stack[7], cidr: Int(cidr))
    }
    // was not able to determine address type
    return nil
}
