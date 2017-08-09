//
//  RemovedPhotoViewController.swift
//  Electo
//
//  Created by 임성훈 on 2017. 8. 8..
//  Copyright © 2017년 RodoPacaGiraffe. All rights reserved.
//

import UIKit
import Photos

class RemovedPhotoViewController: UIViewController {
    fileprivate enum SelectMode: String {
        case on = "Cancel"
        case off = "Choose"
    }
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var chooseButton: UIBarButtonItem!
    
    var photoDataSource: PhotoDataSource?
    fileprivate var selectMode: SelectMode = .off
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView.dataSource = photoDataSource
    }
    
    @IBAction func recoverSelected(_ sender: UIButton) {
        guard let selectedItems = collectionView.indexPathsForSelectedItems else { return }
        guard let removePhotoStore = photoDataSource?.removeStore else { return }
        
        var selectedPhotoAssets: [PHAsset] = []
        
        selectedItems.forEach {
            let selectedPhotoAsset = removePhotoStore.removedPhotoAssets[$0.row]
            selectedPhotoAssets.append(selectedPhotoAsset)
        }
        
        removePhotoStore.removePhotoAssets(toRestore: selectedPhotoAssets)
        collectionView.reloadData()
    }
    
    @IBAction func toggleSelectMode(_ sender: UIBarButtonItem) {
        if selectMode == .off {
            selectMode = .on
        } else {
            selectMode = .off
        }
        
        collectionView.allowsMultipleSelection = !collectionView.allowsMultipleSelection
        chooseButton.title = selectMode.rawValue
    }
    
    @IBAction func cancel(_ sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }
    @IBAction func deleteAction(_ sender: UIButton) {
        switch selectMode {
        case .off:
            PHPhotoLibrary.shared().performChanges({
                
                guard let asset = self.photoDataSource?.removeStore.removedPhotoAssets else { return }
                
                PHAssetChangeRequest.deleteAssets(asset as NSFastEnumeration)
            }) { (success, error) in
                print("success")
            }
        case .on:
            guard let selectedItems = self.collectionView.indexPathsForSelectedItems else { return }
            guard let removePhotoStore = self.photoDataSource?.removeStore else { return }
            var selectedPhotoAssets: [PHAsset] = []
            
            selectedItems.forEach {
                let selectedPhotoAsset = removePhotoStore.removedPhotoAssets[$0.row]
                selectedPhotoAssets.append(selectedPhotoAsset)
            }
            
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.deleteAssets(selectedPhotoAssets as NSFastEnumeration)
            }) { (success, error) in
                print("success")
            }
        }
    }
}

extension RemovedPhotoViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let photoCell = collectionView.cellForItem(at: indexPath)
            as? RemovedPhotoCell ?? RemovedPhotoCell()
        
        switch selectMode {
        case .on:
            photoCell.removedImageView.alpha = 0.3
        case .off:
            break
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        let photoCell = collectionView.cellForItem(at: indexPath)
            as? RemovedPhotoCell ?? RemovedPhotoCell()
        
        switch selectMode {
        case .on:
            photoCell.removedImageView.alpha = 1.0
        case .off:
            break
        }
    }
}
