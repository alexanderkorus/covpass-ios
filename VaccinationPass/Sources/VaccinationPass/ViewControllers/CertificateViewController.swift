//
//  CertificateViewController.swift
//
//
//  Copyright © 2021 IBM. All rights reserved.
//

import Foundation
import UIKit
import VaccinationUI
import Scanner

public class CertificateViewController: UIViewController {
    // MARK: - IBOutlet

    @IBOutlet public var headerView: InfoHeaderView!
    @IBOutlet public var addButton: PrimaryIconButtonContainer!
    @IBOutlet public var collectionView: UICollectionView!
    @IBOutlet public var dotPageIndicator: DotPageIndicator!
    
    // MARK: - Public
    
    public var viewModel: CertificateViewModel!
    public var router: Popup?
    
    // MARK: - Fifecycle
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        setupHeaderView()
        setupActionButton()
        setupCollecttionView()
        setupDotIndicator()
    }
    
    // MARK: - Private
    
    private func setupDotIndicator() {
        dotPageIndicator.delegate = self
        dotPageIndicator.numberOfDots = viewModel.certificates.count
        dotPageIndicator.isHidden = viewModel.certificates.count == 1 ? true : false
    }
    
    private func setupHeaderView() {
        headerView.actionButton.imageEdgeInsets = viewModel.headerButtonInsets
        headerView.headline.text = viewModel.headerTitle
        headerView.headlineFont = viewModel.headerFont
        headerView.buttonImage = viewModel.headerActionImage
    }
    
    private func setupCollecttionView() {
        collectionView.delegate = self
        collectionView.dataSource = self
        let layout = CardFlowLayout()
        layout.scrollDirection = .horizontal
        collectionView.collectionViewLayout = layout
        collectionView.register(UINib(nibName: "\(NoCertificateCollectionViewCell.self)", bundle: UIConstants.bundle), forCellWithReuseIdentifier: "\(NoCertificateCollectionViewCell.self)")
        collectionView.register(UINib(nibName: "\(QrCertificateCollectionViewCell.self)", bundle: UIConstants.bundle), forCellWithReuseIdentifier: "\(QrCertificateCollectionViewCell.self)")
        collectionView.showsHorizontalScrollIndicator = false
    }
    
    private func setupActionButton() {
        view.tintColor = UIConstants.BrandColor.brandAccent
        addButton.iconImage = viewModel?.addButtonImage
        addButton.buttonBackgroundColor = UIConstants.BrandColor.brandAccent
        addButton.action = presentPopup
    }
    
    private func reloadCollectionView() {
        collectionView.reloadData()
        dotPageIndicator.numberOfDots = viewModel.certificates.count
        dotPageIndicator.isHidden = viewModel.certificates.count == 1 ? true : false
    }
    
    private func presentPopup() {
        router?.presentPopup(onTopOf: self)
    }
}

// MARK: - ScannerDelegate

extension CertificateViewController: ScannerDelegate {
    public func result(with value: Result<String, ScanError>) {
        presentedViewController?.dismiss(animated: true, completion: nil)
        switch value {
        case .success(let payload):
            viewModel?.process(payload: payload)
        case .failure(let error):
            print("We have an error: \(error)")
        }
    }
}

// MARK: - UITableViewDataSource

extension CertificateViewController: UICollectionViewDataSource {
    
    public func numberOfSections(in collectionView: UICollectionView) -> Int { 1 }
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        viewModel?.certificates.count ?? 0
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: viewModel.reuseIdentifier(for: indexPath), for: indexPath) as? BaseCardCollectionViewCell else { return UICollectionViewCell() }
        viewModel.configure(cell: cell, at: indexPath)
        return cell
    }
}

// MARK: - UITableViewDelegate

extension CertificateViewController: UICollectionViewDelegate {
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
    }
    
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let visibleRect = CGRect(origin: collectionView.contentOffset, size: collectionView.bounds.size)
        let visiblePoint = CGPoint(x: visibleRect.midX, y: visibleRect.midY)
        guard let visibleIndexPath = collectionView.indexPathForItem(at: visiblePoint) else { return }
        dotPageIndicator.selectDot(withIndex: visibleIndexPath.item)
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension CertificateViewController: UICollectionViewDelegateFlowLayout {
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        CGSize(width: collectionView.bounds.width - 40, height: collectionView.bounds.height)
    }
}

// MARK: - DotPageIndicatorDelegate

extension CertificateViewController: DotPageIndicatorDelegate {
    public func dotPageIndicator(_ dotPageIndicator: DotPageIndicator, didTapDot index: Int) {
        collectionView.scrollToItem(at: IndexPath(item: index, section: 0), at: .left, animated: true)
    }
}

// MARK: - StoryboardInstantiating

extension CertificateViewController: StoryboardInstantiating {
    public static var storyboardName: String {
        VaccinationPassConstants.Storyboard.Pass
    }
}

// MARK: - UpdateDelegate

extension CertificateViewController: ReloadDelegate {
    public func shouldReload() {
        reloadCollectionView()
    }
}
