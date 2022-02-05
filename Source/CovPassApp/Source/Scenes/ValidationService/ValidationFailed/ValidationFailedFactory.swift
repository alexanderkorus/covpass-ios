//
//  ValidationFailedFactory.swift
//
//  © Copyright IBM Deutschland GmbH 2021
//  SPDX-License-Identifier: Apache-2.0
//

import CovPassUI
import CovPassCommon
import UIKit
import PromiseKit

struct ValidationFailedFactory: ResolvableSceneFactory {

    // MARK: - Properties
    let ticket: ValidationServiceInitialisation

    // MARK: - Lifecycle

    init(ticket: ValidationServiceInitialisation) {
        self.ticket = ticket
    }

    func make(resolvable: Resolver<Bool>) -> UIViewController {
        let viewModel = ValidationFailedViewModel(resolvable: resolvable,
                                                  ticket: ticket)
        let viewController = ValidationFailedViewController(viewModel: viewModel)
        return viewController
    }
}
