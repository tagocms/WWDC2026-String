//
//  String.swift
//  String
//
//  Created by Tiago Camargo Maciel dos Santos on 25/02/26.
//

import Foundation

extension String {
    /// Returns the ranges of the attributed string in the source (content body) that match strings for the desired pattern as Array of Ranges.
    static func ranges(
        of pattern: AttributedString,
        in source: AttributedString,
        options: String.CompareOptions = [.caseInsensitive]
    ) -> [Range<AttributedString.Index>] {
        let sourceString = String(source.characters)
        let patternString = String(pattern.characters)

        var ranges: [Range<AttributedString.Index>] = []
        var searchRange = sourceString.startIndex..<sourceString.endIndex

        while let stringRange = sourceString.range(of: patternString, options: options, range: searchRange) {
            // Map String indices back to AttributedString indices
            let lowerOffset = sourceString.distance(from: sourceString.startIndex, to: stringRange.lowerBound)
            let upperOffset = sourceString.distance(from: sourceString.startIndex, to: stringRange.upperBound)

            let attrLower = source.index(source.startIndex, offsetByCharacters: lowerOffset)
            let attrUpper = source.index(source.startIndex, offsetByCharacters: upperOffset)

            ranges.append(attrLower..<attrUpper)
            searchRange = stringRange.upperBound..<sourceString.endIndex
        }

        return ranges
    }
    
    /// (Overload) Returns the ranges of the attributed string in the source (content body) that match strings for the desired pattern as RangeSet.
    static func ranges(
        of pattern: AttributedString,
        in source: AttributedString,
        options: String.CompareOptions = [.caseInsensitive]
    ) -> RangeSet<AttributedString.Index> {
        return RangeSet(Self.ranges(of: pattern, in: source, options: options))
    }
}
