//
//  MockExtendedCBORWebToken.swift
//
//  © Copyright IBM Deutschland GmbH 2021
//  SPDX-License-Identifier: Apache-2.0
//

@testable import CovPassCommon
import XCTest

extension ExtendedCBORWebToken {
    // Quick hack to provide a testable web token
    static func mock() throws -> Self {
        // CBORWebToken.json
        let data = try XCTUnwrap("""
        {"1":"DE","4":1682239131,"6":1619167131,"-260":{"1":{"nam":{"gn":"Erika Dörte","fn":"Schmitt Mustermann","gnt":"ERIKA<DOERTE","fnt":"SCHMITT<MUSTERMANN"},"dob":"1964-08-12","v":[{"ci":"01DE/84503/1119349007/DXSGWLWL40SU8ZFKIYIBK39A3#S","co":"DE","dn":2,"dt":"2021-02-02","is":"Bundesministerium für Gesundheit","ma":"ORG-100030215","mp":"EU/1/20/1528","sd":2,"tg":"840539006","vp":"1119349007"}],"ver":"1.0.0"}}}
        """.data(using: .utf8))
        let token = try JSONDecoder().decode(CBORWebToken.self, from: data)
        let extendedToken = ExtendedCBORWebToken(vaccinationCertificate: token, vaccinationQRCodeData: "")
        // ...
        return extendedToken
    }
}
