//
//  RemovedPhotoViewController.swift
//  Electo
//
//  Created by RodoPacaGiraffe on 2017. 8. 8..
//  Copyright © 2017년 RodoPacaGiraffe. All rights reserved.
//

import UIKit
import Photos

fileprivate enum SelectMode: String {
    case on = "Cancel"
    case off = "Choose"
}

fileprivate enum CommittedMode: String {
    case recorver
    case delete
}

fileprivate struct Constants {
    struct AlertCommitResult {
        static let resultLabelHeight: CGFloat = 50.0
        static let resultLabelRoundBorderDegree: CGFloat = 5.0
        static let duration: TimeInterval = 0.5
        static let fadeOutDelay: TimeInterval = 0.5
        static let alphaForAppear: CGFloat = 1.0
        static let alphaForDisappear: CGFloat = 0.0
    }
    
    struct SlideToDismiss {
        static let activateBounds: CGFloat = 200.0
        static let duration: TimeInterval = 0.2
    }
}

class TemporaryPhotoViewController: UIViewController {
    @IBOutlet fileprivate var deleteSelectedButton: UIButton!
    @IBOutlet fileprivate var recoverSelectedButton: UIButton!
    @IBOutlet private var flowLayout: UICollectionViewFlowLayout!
    @IBOutlet private var collectionView: UICollectionView!
    @IBOutlet private var chooseButton: UIBarButtonItem!
    @IBOutlet private var buttonForEditStackView: UIStackView!
    @IBOutlet private var buttonForNormalStackView: UIStackView!
    
    private var originalNavigationPosition: CGPoint?
    private var originalPosition: CGPoint?
    private var currentTouchPosition: CGPoint?
    var photoDataSource: PhotoDataSource?
  
    fileprivate var selectMode: SelectMode = .off {
        didSet {
            toggleHiddenState(forViews: [buttonForEditStackView, buttonForNormalStackView])
            chooseButton.title = NSLocalizedString(selectMode.rawValue, comment: "")
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setCollectionView()
        setCellSize()
        
        NotificationCenter.default.addObserver(self, selector: #selector (reloadData),
                                               name: NotificationName.requiredReload, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    private func setCollectionView() {
        collectionView.dataSource = photoDataSource
        collectionView.allowsMultipleSelection = true
        
        let bottomInset: CGFloat = collectionView.frame.maxY - buttonForNormalStackView.frame.origin.y
        collectionView.contentInset = UIEdgeInsets(top: 0.0, left: 0.0, bottom: bottomInset, right: 0.0)
        collectionView.scrollIndicatorInsets = UIEdgeInsets(top: 0.0, left: 0.0, bottom: bottomInset, right: 0.0)
    }
    
    private func setCellSize() {
        let width = (collectionView.bounds.width / 4) - flowLayout.minimumLineSpacing * 2
        flowLayout.itemSize.width = width
        flowLayout.itemSize.height = width
    }
    
    private func toggleHiddenState(forViews views: [UIView]) {
        views.forEach {
            $0.isHidden = !$0.isHidden
        }
    }
    
    fileprivate func selectedPhotoAssets() -> [PHAsset] {
        guard let selectedItems = self.collectionView.indexPathsForSelectedItems else { return [] }
        guard let temporaryPhotoStore = self.photoDataSource?.temporaryPhotoStore else { return [] }
        
        var selectedPhotoAssets: [PHAsset] = []
        
        selectedItems.forEach {
            let selectedPhotoAsset = temporaryPhotoStore.photoAssets[$0.row]
            selectedPhotoAssets.append(selectedPhotoAsset)
        }
        
        return selectedPhotoAssets
    }
    
    @objc private func reloadData() {
        DispatchQueue.main.async { [weak self] in
            self?.collectionView.reloadData()
        }
    }
    
    private func initSelection() {
        guard let selectedItems = collectionView.indexPathsForSelectedItems else {
            return
        }
        
        collectionView.reloadItems(at: selectedItems)
    }
    
    @IBAction private func toggleSelectMode(_ sender: UIBarButtonItem) {
        if selectMode == .off {
            selectMode = .on
            if self.selectedPhotoAssets().isEmpty {
                recoverSelectedButton.isEnabled = false
                deleteSelectedButton.isEnabled = false
            }
        } else {
            selectMode = .off
            
            initSelection()
        }
    }
    
    private func alertCommitResult(committedCount: Int, committedMode: CommittedMode) {
        let label: UILabel = UILabel()
        var localizedMessage: String = ""
        
        switch committedMode {
        case .recorver:
            localizedMessage = NSLocalizedString(LocalizationKey.numberOfPhotosRecovered, comment: "")
            
        case .delete:
            localizedMessage = NSLocalizedString(LocalizationKey.numberOfPhotosDeleted, comment: "")
        }
        
        if Locale.preferredLanguages.first == Language.arabic {
            label.text = committedCount.toArabic() + localizedMessage
        } else {
            label.text = String(format: localizedMessage, committedCount)
        }
        
        label.backgroundColor = UIColor.lightGray.withAlphaComponent(0.8)
        label.alpha = 0
        label.textAlignment = .center
        label.adjustsFontSizeToFitWidth = true
        label.frame = CGRect(x: self.view.frame.width / 4,
                             y: self.view.frame.height / 3,
                             width: self.view.frame.width / 2,
                             height: Constants.AlertCommitResult.resultLabelHeight)
        label.makeRoundBorder(degree: Constants.AlertCommitResult.resultLabelRoundBorderDegree)
        
        guard let naviController = UIApplication.shared.keyWindow?.rootViewController
            as? UINavigationController else { return }
        guard let topViewController = naviController.topViewController else { return }

        if topViewController.presentedViewController != nil {
            topViewController.presentedViewController?.view.addSubview(label)
        } else {
            topViewController.view.addSubview(label)
        }
        
        commitResultAppear(label)
    }
    
    private func commitResultAppear(_ label: UILabel) {
        UIView.animate(withDuration: Constants.AlertCommitResult.duration,
            animations: {
            label.alpha = Constants.AlertCommitResult.alphaForAppear
        }, completion: { _ in
            UIView.animate(withDuration: Constants.AlertCommitResult.duration,
                delay: Constants.AlertCommitResult.fadeOutDelay,
                options: .beginFromCurrentState,
                animations: {
                label.alpha = Constants.AlertCommitResult.alphaForDisappear
            }, completion: { _ in
                label.removeFromSuperview()
            })
        })
    }
    
    fileprivate func popIfCountIsEmptyAfterCommitted(count: Int, message: CommittedMode) {
        guard let navigationController = self.presentingViewController
            as? UINavigationController else { return }
        
        guard let temporaryPhotoAssets = self.photoDataSource?.temporaryPhotoStore.photoAssets else { return }
        guard temporaryPhotoAssets.isEmpty else {
            self.alertCommitResult(committedCount: count, committedMode: message)
            return
        }
        
        if navigationController.topViewController is ClassifiedPhotoViewController {
            self.dismiss(animated: true ) { [weak self] _ in
                self?.alertCommitResult(committedCount: count, committedMode: message)
            }
        } else {
            self.dismiss(animated: false) { [weak self] _ in
                navigationController.popToRootViewController(animated: true)
                self?.alertCommitResult(committedCount: count, committedMode: message)
            }
        }
        
    }
    
    @IBAction private func recoverAll(_ sender: UIButton) {
        recoverAlertController(title: LocalizationKey.recoverAllPhotos) { [weak self] _ in
            guard let temporaryPhotoStore = self?.photoDataSource?.temporaryPhotoStore else { return }
            
            let allRemovedPhotoAssets = temporaryPhotoStore.photoAssets
            let recoverCount = allRemovedPhotoAssets.count
            temporaryPhotoStore.remove(photoAssets: allRemovedPhotoAssets)

            self?.collectionView.reloadSections(IndexSet(integer: 0))
            
            NotificationCenter.default.post(name: NotificationName.requiredReload, object: nil)
            
           self?.popIfCountIsEmptyAfterCommitted(count: recoverCount, message: CommittedMode.recorver)
        }
    }
    
    @IBAction private func recoverSelected(_ sender: UIButton) {
        recoverAlertController(title: LocalizationKey.recoverSelectedPhotos) { [weak self] _ in
            guard let temporaryPhotoStore = self?.photoDataSource?.temporaryPhotoStore else { return }
            guard let recoverCount = self?.selectedPhotoAssets().count else { return }
            guard let temporaryVC = self else { return }
            
            temporaryPhotoStore.remove(photoAssets: temporaryVC.selectedPhotoAssets())
            self?.collectionView.performBatchUpdates({
                self?.deleteSelectedButton.isEnabled = false
                self?.recoverSelectedButton.isEnabled = false
                guard let selectedItems = self?.collectionView.indexPathsForSelectedItems else { return }
                self?.collectionView.deleteItems(at: selectedItems)
            }, completion: nil)

            temporaryVC.alertCommitResult(committedCount: recoverCount, committedMode: .recorver)
            NotificationCenter.default.post(name: NotificationName.requiredReload, object: nil)
            
            self?.popIfCountIsEmptyAfterCommitted(count: recoverCount, message: CommittedMode.recorver)
        }
    }
    
    @IBAction private func deleteAll(_ sender: UIButton) {
        guard let temporaryPhotoStore = photoDataSource?.temporaryPhotoStore else { return }
        let deleteCount = temporaryPhotoStore.photoAssets.count
        temporaryPhotoStore.removePhotoFromLibrary(with: temporaryPhotoStore.photoAssets) { [weak self] in
            self?.collectionView.reloadSections(IndexSet(integer: 0))
            self?.dismiss(animated: true, completion: {
                self?.alertCommitResult(committedCount: deleteCount, committedMode: .delete)
            })
        }
    }
    
    @IBAction private func deleteSelected(_ sender: UIButton) {
        guard let temporaryPhotoStore = photoDataSource?.temporaryPhotoStore else { return }
        
        let deleteCount = selectedPhotoAssets().count
        temporaryPhotoStore.removePhotoFromLibrary(with: selectedPhotoAssets()) {
            [weak self] in
            self?.collectionView.performBatchUpdates({
                self?.deleteSelectedButton.isEnabled = false
                self?.recoverSelectedButton.isEnabled = false
                guard let selectedItems = self?.collectionView.indexPathsForSelectedItems else { return }
                self?.collectionView.deleteItems(at: selectedItems)
            }, completion: { _ in
                self?.popIfCountIsEmptyAfterCommitted(count: deleteCount, message: .delete)
            })
        }
    }
    
    @IBAction private func cancel(_ sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }
    
    private func recoverAlertController(title: String,
                                        completion: @escaping (UIAlertAction) -> Void) {
        
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let recoverAction = UIAlertAction(title: NSLocalizedString(title, comment: ""),
                                          style: .default, handler: completion)
        let cancelAction = UIAlertAction(title: NSLocalizedString(LocalizationKey.cancel, comment: ""),
                                         style: .cancel, handler: nil)
        
        alertController.addAction(recoverAction)
        alertController.addAction(cancelAction)

        self.present(alertController, animated: true, completion: nil)
    }
    
    @IBAction private func slideToDismiss(_ sender: UIPanGestureRecognizer) {
        let translation = sender.translation(in: self.view)
        let originalViewFrame = self.view.frame.origin
       
        switch sender.state {
        case .began:
            originalPosition = view.center
            originalNavigationPosition = navigationController?.navigationBar.center
            currentTouchPosition = sender.location(in: self.view)
        case .changed:
            if translation.y > Constants.SlideToDismiss.activateBounds {
                UIView.animate(withDuration: Constants.SlideToDismiss.duration, animations: {
                    self.view.frame.origin = CGPoint(x: originalViewFrame.x,
                                                     y: translation.y + 64)
                    self.navigationController?.navigationBar.frame.origin = CGPoint(x: originalViewFrame.x,
                                                                                    y: translation.y + 20)
                })
            }
        case .ended:
            dismissWhenTouchesEnded(sender)
        default:
            break
        }
    }
    
    private func dismissWhenTouchesEnded(_ sender: UIPanGestureRecognizer) {
        var originalViewFrame = self.view.frame.origin
        var originalNavigationBarFrame = self.navigationController?.navigationBar.frame.origin
        let translation = sender.translation(in: self.view)
        
        guard translation.y > self.view.frame.height / 2  else {
            UIView.animate(withDuration: Constants.SlideToDismiss.duration, animations: { [weak self] _ in
                guard let originalPosition = self?.originalPosition else { return }
                guard let originalNavigationPosition = self?.originalNavigationPosition else { return }
                
                self?.view.center = originalPosition
                self?.navigationController?.navigationBar.center = originalNavigationPosition
            })
            
            return
        }
        
        UIView.animate(withDuration: Constants.SlideToDismiss.duration, animations: {
            originalViewFrame = CGPoint(x: originalViewFrame.x,
                                        y: self.view.frame.size.height)
            originalNavigationBarFrame = CGPoint(x: originalViewFrame.x,
                                                 y: self.view.frame.size.height)
        }, completion: { [weak self] completed in
            guard completed == true else { return }
            self?.dismiss(animated: true, completion: nil)
        })
    }
}

extension TemporaryPhotoViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let photoCell = collectionView.cellForItem(at: indexPath)
            as? TemporaryPhotoCell else { return }
        
        switch selectMode {
        case .on:
            deleteSelectedButton.isEnabled = true
            recoverSelectedButton.isEnabled = true
            photoCell.select()
        case .off:
            collectionView.deselectItem(at: indexPath, animated: true)
            guard let temporaryPhotoStore = photoDataSource?.temporaryPhotoStore else { return }
            guard let detailViewController = storyboard?.instantiateViewController(withIdentifier: StoryBoardIdentifier.detailViewController)
                as? DetailPhotoViewController else { return }
            
            detailViewController.selectedSectionAssets = temporaryPhotoStore.photoAssets
            detailViewController.identifier = PreviousVCIdentifier.fromTemporaryPhotoVC
            detailViewController.pressedIndexPath = indexPath
            detailViewController.navigationItem.title = temporaryPhotoStore.photoAssets[indexPath.item]
                .creationDate?.toDateString()
            
            self.show(detailViewController, sender: self)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        let photoCell = collectionView.cellForItem(at: indexPath)
            as? TemporaryPhotoCell ?? TemporaryPhotoCell()
        photoCell.deSelect()
        
        if selectedPhotoAssets().isEmpty {
            deleteSelectedButton.isEnabled = false
            recoverSelectedButton.isEnabled = false
        }
    }
}

extension TemporaryPhotoViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}

