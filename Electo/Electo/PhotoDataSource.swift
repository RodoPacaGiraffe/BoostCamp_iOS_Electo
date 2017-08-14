//
//  PhotoDataSource.swift
//  Electo
//
//  Created by RodoPacaGiraffe on 2017. 8. 7..
//  Copyright © 2017년 RodoPacaGiraffe. All rights reserved.
//

import UIKit
import Photos

class PhotoDataSource: NSObject, NSKeyedUnarchiverDelegate {
    var photoStore: PhotoStore = PhotoStore()
    var temporaryPhotoStore: TemporaryPhotoStore = TemporaryPhotoStore() {
        didSet {
            temporaryPhotoStore.delegate = photoStore
        }
    }
    
    override init() {
        temporaryPhotoStore.delegate = photoStore
        
        super.init()
    }
}

extension PhotoDataSource: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return photoStore.classifiedPhotoAssets.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Constants.maximumSection
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Constants.cellIdentifier, for: indexPath) as? ClassifiedPhotoCell ?? ClassifiedPhotoCell()
        
        let photoAssets = photoStore.classifiedPhotoAssets[indexPath.section]
        var fetchedImages: [UIImage] = .init()
        
        let options: PHImageRequestOptions = .init()
        options.isSynchronous = true
        photoAssets.forEach {
            $0.fetchImage(size: Constants.fetchImageSize,
                          contentMode: .aspectFill, options: options) { photoImage in
                            guard let photoImage = photoImage else { return }
                            fetchedImages.append(photoImage)
                            
                            if photoAssets.count == fetchedImages.count {
                            cell.cellImages = fetchedImages
                            }
            }
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        guard editingStyle == .delete else { return }
        
        let assets = photoStore.classifiedPhotoAssets[indexPath.section]
        
        temporaryPhotoStore.insert(photoAssets: assets)
        tableView.deleteSections(IndexSet(integer: indexPath.section), with: .automatic)
    }
}

// TemporaryPhotoViewController - DataSource
extension PhotoDataSource: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return temporaryPhotoStore.photoAssets.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Constants.cellIdentifier,
            for: indexPath) as? TemporaryPhotoCell ?? TemporaryPhotoCell()
        let removedPhotoAsset = temporaryPhotoStore.photoAssets[indexPath.item]
        
        removedPhotoAsset.fetchImage(size: Constants.fetchImageSize,
                                     contentMode: .aspectFill, options: nil) { removedPhotoImage in
                                        guard let removedPhotoImage = removedPhotoImage else { return }
                                                
                                        cell.addRemovedImage(removedPhotoImage: removedPhotoImage)
        }
    
        return cell
    }
}

