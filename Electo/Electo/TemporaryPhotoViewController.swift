//
//  RemovedPhotoViewController.swift
//  Electo
//
//  Created by 임성훈 on 2017. 8. 8..
//  Copyright © 2017년 RodoPacaGiraffe. All rights reserved.
//

import UIKit
import Photos

class TemporaryPhotoViewController: UIViewController {
    fileprivate enum SelectMode: String {
        case on = "Cancel"
        case off = "Choose"
    }
    
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
                                               name: Constants.requiredReload, object: nil)
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
    
    @IBAction func toggleSelectMode(_ sender: UIBarButtonItem) {
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
    
    func alertCountOfPhotos(count: Int, message: String) {
        let label = UILabel()
        label.text = "\(count) \(message)"
        label.backgroundColor = UIColor.lightGray.withAlphaComponent(0.8)
        label.alpha = 0
        label.textAlignment = .center
        
        label.frame = CGRect(x: self.view.frame.width / 4,
                                      y: self.view.center.y - 64,
                                      width: self.view.frame.width / 2,
                                      height: 50)
        label.makeRoundBorder(degree: 5)
        OperationQueue.main.addOperation {
            
            let rootViewController = UIApplication.shared.keyWindow?.rootViewController
            let viewController = rootViewController?.presentedViewController ?? rootViewController
            viewController?.view.superview?.addSubview(label)
            self.countAppearAnimation(label)
            
        }
    }
    
    func selectedAlertCountOfPhotos(count: Int, message: String) {
        let label = UILabel()
        label.text = "\(count) \(message)"
        label.backgroundColor = UIColor.lightGray.withAlphaComponent(1)
        label.alpha = 0
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 20)
        
        label.frame = CGRect(x: (self.view.frame.width) / 4, y: (view.frame.height)/2, width: 200, height: 60)
        label.makeRoundBorder(degree: 5)
        self.view.addSubview(label)
        OperationQueue.main.addOperation {
            self.countAppearAnimation(label)
        }
    }
    
    func countAppearAnimation(_ label: UILabel) {
        UIView.animate(withDuration: 0.5, animations: {
            label.alpha = 1
        }, completion: { _ in
            UIView.animate(withDuration: 0.5, delay: 0.5, options: .beginFromCurrentState, animations: {
                label.alpha = 0
            }, completion: { _ in
                label.removeFromSuperview()
            })
            
        })
    }
    
    @IBAction func recoverAll(_ sender: UIButton) {
        recoverAlertController(title: "Recover All Photos") { [weak self] _ in
            guard let temporaryPhotoStore = self?.photoDataSource?.temporaryPhotoStore else { return }
            
            let allRemovedPhotoAssets = temporaryPhotoStore.photoAssets
            let recoverCount = allRemovedPhotoAssets.count
            temporaryPhotoStore.remove(photoAssets: allRemovedPhotoAssets)

            self?.collectionView.reloadSections(IndexSet(integer: 0))

            guard let navigationController = self?.presentingViewController
                as? UINavigationController else { return }
            
            NotificationCenter.default.post(name: Constants.requiredReload, object: nil)
            
            if navigationController.topViewController is ClassifiedPhotoViewController {
                self?.dismiss(animated: true, completion: {
                    self?.alertCountOfPhotos(count: recoverCount, message: "photos recovered.")
                })
            } else {
                self?.dismiss(animated: false) {
                        navigationController.popToRootViewController(animated: true)
                    }
                self?.alertCountOfPhotos(count: recoverCount, message: "photos recovered.")
                }
            }
    }
    
    @IBAction func recoverSelected(_ sender: UIButton) {
        recoverAlertController(title: "Recover Selected Photos") { [weak self] _ in
            guard let temporaryPhotoStore = self?.photoDataSource?.temporaryPhotoStore else { return }
            guard let recoverCount = self?.selectedPhotoAssets().count else { return }
            guard let temporaryVC = self else { return }
            
            temporaryPhotoStore.remove(photoAssets: temporaryVC.selectedPhotoAssets())
            self?.collectionView.performBatchUpdates({
                guard let selectedItems = self?.collectionView.indexPathsForSelectedItems else { return }
                self?.collectionView.deleteItems(at: selectedItems)
            }, completion: nil)


            temporaryVC.selectedAlertCountOfPhotos(count: recoverCount, message: "photos recovered.")
            guard let navigationController = temporaryVC.presentingViewController
                as? UINavigationController else { return }
            NotificationCenter.default.post(name: Constants.requiredReload, object: nil)
        
            //TODO: 선택 삭제 후 그대로
//            if navigationController.topViewController is ClassifiedPhotoViewController {
//                temporaryVC.dismiss(animated: true, completion: nil)
//            } else {
//                temporaryVC.dismiss(animated: false) {
//                    navigationController.popToRootViewController(animated: true)
//                }
//            }
        }
    }
    
    @IBAction func deleteAll(_ sender: UIButton) {
        guard let temporaryPhotoStore = photoDataSource?.temporaryPhotoStore else { return }

        
        temporaryPhotoStore.removePhotoFromLibrary(with: temporaryPhotoStore.photoAssets) { [weak self] in
        let deleteCount = temporaryPhotoStore.photoAssets.count
            self?.collectionView.reloadSections(IndexSet(integer: 0))
            self?.dismiss(animated: true, completion: {
                self?.alertCountOfPhotos(count: deleteCount, message: "photos deleted.")
            })
        }
    }
    
    @IBAction func deleteSelected(_ sender: UIButton) {
        guard let temporaryPhotoStore = photoDataSource?.temporaryPhotoStore else { return }
       let deleteCount = selectedPhotoAssets().count        
        temporaryPhotoStore.removePhotoFromLibrary(with: selectedPhotoAssets()) {
            [weak self] in
            self?.collectionView.performBatchUpdates({
                guard let selectedItems = self?.collectionView.indexPathsForSelectedItems else { return }
              
                self?.collectionView.deleteItems(at: selectedItems)
            }, completion: { _ in
             self?.selectedAlertCountOfPhotos(count: deleteCount, message: "photos deleted.")
            })

        }
    }
    
    @IBAction func cancel(_ sender: UIBarButtonItem) {
        
        self.dismiss(animated: true, completion: nil)
    }
    
    private func recoverAlertController(title: String,
                                        completion: @escaping (UIAlertAction) -> Void) {
        
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let recoverAction = UIAlertAction(title: NSLocalizedString(title, comment: ""),
                                          style: .default, handler: completion)
        let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""),
                                         style: .destructive, handler: nil)
        
        alertController.addAction(recoverAction)
        alertController.addAction(cancelAction)
        alertController.view.tintColor = UIColor.darkGray
       
        present(alertController, animated: true, completion: nil)
    }
    
    @IBAction func slideToDismiss(_ sender: UIPanGestureRecognizer) {
        let translation = sender.translation(in: self.view)
        let originalViewFrame = self.view.frame.origin
       
        switch sender.state {
        case .began:
            originalPosition = view.center
            originalNavigationPosition = navigationController?.navigationBar.center
            currentTouchPosition = sender.location(in: self.view)
        case .changed:
            if translation.y > 200 {
                UIView.animate(withDuration: 0.2, animations: { 
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
    
    func dismissWhenTouchesEnded(_ sender: UIPanGestureRecognizer) {
        var originalViewFrame = self.view.frame.origin
        var originalNavigationBarFrame = self.navigationController?.navigationBar.frame.origin
        let translation = sender.translation(in: self.view)
        
        guard translation.y > 300  else {
            UIView.animate(withDuration: 0.2, animations: { [weak self] _ in
                guard let originalPosition = self?.originalPosition else { return }
                guard let originalNavigationPosition = self?.originalNavigationPosition else { return }
                
                self?.view.center = originalPosition
                self?.navigationController?.navigationBar.center = originalNavigationPosition
            })
            
            return
        }
        
        UIView.animate(withDuration: 0.2,
            animations: {
                originalViewFrame = CGPoint(x: originalViewFrame.x,
                                            y: self.view.frame.size.height)
                originalNavigationBarFrame = CGPoint(x: originalViewFrame.x,
                                                     y: self.view.frame.size.height)
        },
            completion: { [weak self] completed in
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
            guard let detailViewController = storyboard?.instantiateViewController(withIdentifier:  "detailViewController") as? DetailPhotoViewController else { return }
            
            detailViewController.selectedSectionAssets = temporaryPhotoStore.photoAssets
            detailViewController.identifier = "fromTemporaryViewController"
            
            guard let selectedThumbnailImage = photoCell.thumbnailImageView.image else { return }
            detailViewController.thumbnailImages.append(selectedThumbnailImage)
            detailViewController.pressedIndexPath = indexPath
            
            detailViewController.navigationItem.title = temporaryPhotoStore.photoAssets[indexPath.item]
                .creationDate?.toDateString()
            
            show(detailViewController, sender: self)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        let photoCell = collectionView.cellForItem(at: indexPath)
            as? TemporaryPhotoCell ?? TemporaryPhotoCell()
        photoCell.deSelect()
        
        if self.selectedPhotoAssets().isEmpty {
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

