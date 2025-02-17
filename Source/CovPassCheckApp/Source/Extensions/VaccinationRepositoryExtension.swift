//
//  VaccinationRepositoryExtension.swift
//
//
//  © Copyright IBM Deutschland GmbH 2021
//  SPDX-License-Identifier: Apache-2.0
//

import CovPassCommon
import Foundation

extension VaccinationRepository {
    static func create() -> VaccinationRepository {
        VaccinationRepository(
            service: APIService.create(),
            keychain: KeychainPersistence(),
            userDefaults: UserDefaultsPersistence(),
            boosterLogic: BoosterLogic.create(),
            publicKeyURL: Bundle.commonBundle.url(forResource: XCConfiguration.value(String.self, forKey: "TRUST_LIST_PUBLIC_KEY"), withExtension: nil)!,
            initialDataURL: Bundle.commonBundle.url(forResource: XCConfiguration.value(String.self, forKey: "TRUST_LIST_STATIC_DATA"), withExtension: nil)!
        )
    }
}
