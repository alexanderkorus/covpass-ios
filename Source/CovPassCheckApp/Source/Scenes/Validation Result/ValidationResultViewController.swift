//
//  ValidationResultViewController.swift
//
//
//  © Copyright IBM Deutschland GmbH 2021
//  SPDX-License-Identifier: Apache-2.0
//

import CovPassUI
import UIKit
import CovPassCommon

private enum Constants {
    static let confirmButtonLabel = "validation_check_popup_valid_vaccination_button_title".localized

    enum Accessibility {
        static let image = VoiceOverOptions.Settings(label: "accessibility_image_alternative_text".localized)
        static let close = VoiceOverOptions.Settings(label: "accessibility_popup_label_close".localized)
    }
}

class ValidationResultViewController: UIViewController {
    // MARK: - IBOutlet

	@IBOutlet weak var safeQRCodeButton: CustomToolbarView!
	@IBOutlet var stackView: UIStackView!
    @IBOutlet var toolbarView: CustomToolbarView!
    @IBOutlet var headline: InfoHeaderView!
    @IBOutlet var imageContainerView: UIStackView!
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var resultView: ParagraphView!
    @IBOutlet var paragraphStackView: UIStackView!
    @IBOutlet var infoView: PlainLabel!

    // MARK: - Properties

    private(set) var viewModel: ValidationResultViewModel

    // MARK: - Lifecycle

    @available(*, unavailable)
    required init?(coder _: NSCoder) { fatalError("init?(coder: NSCoder) not implemented yet") }

    init(viewModel: ValidationResultViewModel) {
        self.viewModel = viewModel
        super.init(nibName: String(describing: Self.self), bundle: .main)
        self.viewModel.delegate = self
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureHeadline()
        configureToolbarView()
        configureAccessibility()
        updateViews()
    }

    // MARK: - Private

    private func updateViews() {
        stackView.setCustomSpacing(.space_24, after: imageContainerView)
        stackView.setCustomSpacing(.space_24, after: resultView)

        imageView.image = viewModel.icon
        imageView.enableAccessibility(label: Constants.Accessibility.image.label)
        
        resultView.attributedTitleText = viewModel.resultTitle.styledAs(.header_1)
        resultView.attributedBodyText = viewModel.resultBody.styledAs(.body)
        resultView.bottomBorder.isHidden = true

        infoView.attributedText = viewModel.info?.styledAs(.body).colored(.onBackground40)
        infoView.layoutMargins = .init(top: .zero, left: .space_24, bottom: .zero, right: .space_24)

        paragraphStackView.subviews.forEach {
            $0.removeFromSuperview()
            self.paragraphStackView.removeArrangedSubview($0)
        }
        viewModel.paragraphs.forEach {
            let p = ParagraphView()
            p.attributedTitleText = $0.title.styledAs(.header_3)
            p.attributedBodyText = $0.subtitle.styledAs(.body)
            p.image = $0.icon?.withRenderingMode(.alwaysTemplate)
            p.imageView.tintColor = .brandAccent
            p.bottomBorder.isHidden = true
            p.layoutMargins.bottom = .space_20
            self.paragraphStackView.addArrangedSubview(p)
        }

        UIAccessibility.post(notification: .layoutChanged, argument: resultView.titleLabel)
    }

    private func configureHeadline() {
        headline.attributedTitleText = "".styledAs(.header_3)
        headline.action = { [weak self] in
            self?.viewModel.cancel()
        }
        headline.image = .close
        headline.actionButton.enableAccessibility(label: Constants.Accessibility.close.label)
        stackView.setCustomSpacing(.space_24, after: headline)
    }

    private func configureToolbarView() {
        toolbarView.state = .confirm(Constants.confirmButtonLabel)
        toolbarView.delegate = self

		safeQRCodeButton.state = .saveQRCodeButton
		safeQRCodeButton.delegate = self
    }

    private func configureAccessibility() {
        headline.actionButton.enableAccessibility(label: Constants.Accessibility.close.label)
    }
}

// MARK: - ViewModelDelegate

extension ValidationResultViewController: ResultViewModelDelegate {
    func viewModelDidUpdate() {
        updateViews()
    }

    func viewModelDidChange(_ newViewModel: ValidationResultViewModel) {
        viewModel = newViewModel
        viewModel.delegate = self
        updateViews()
    }
}

// MARK: - CustomToolbarViewDelegate

extension ValidationResultViewController: CustomToolbarViewDelegate {
    func customToolbarView(_: CustomToolbarView, didTap buttonType: ButtonItemType) {
        switch buttonType {
        case .textButton:
            viewModel.scanNextCertifcate()
		case .saveQrCodeButton:
			if let data = QRCodeImageState.default.qrCodeData, let image = data.generateQRCodeNoCI() {
				UIImageWriteToSavedPhotosAlbum(
					image, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
				QRCodeImageState.default.qrCodeData = nil
			}
		default:
            return
        }
    }

	@objc func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
		if let error = error {
			// we got back an error!
			let ac = UIAlertController(title: "Save error", message: error.localizedDescription, preferredStyle: .alert)
			ac.addAction(UIAlertAction(title: "OK", style: .default))
			present(ac, animated: true)
		} else {
			let ac = UIAlertController(title: "Saved!", message: "Your altered image has been saved to your photos.", preferredStyle: .alert)
			ac.addAction(UIAlertAction(title: "OK", style: .default))
			present(ac, animated: true)
		}
	}
}

// MARK: - ModalInteractiveDismissibleProtocol

extension ValidationResultViewController: ModalInteractiveDismissibleProtocol {
    func canDismissModalViewController() -> Bool {
        viewModel.isCancellable()
    }

    func modalViewControllerDidDismiss() {
        viewModel.cancel()
    }
}
