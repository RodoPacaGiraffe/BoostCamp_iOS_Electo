//
//  PhotoStore.swift
//  Electo
//
//  Created by RodoPacaGiraffe on 2017. 8. 7..
//  Copyright © 2017년 RodoPacaGiraffe. All rights reserved.
//

import Foundation
import Photos

class PhotoStore: PhotoClassifiable {
    fileprivate(set) var photoAssets: [PHAsset] = []
    fileprivate(set) var classifiedPhotoAssets: [[PHAsset]] = []
    
    func fetchPhotoAsset() {
        let fetchOptions = PHFetchOptions()
        
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: Order.creationDate.rawValue,
                                                         ascending: false)]
        
        let fetchResult = PHAsset.fetchAssets(with: fetchOptions)
        
        for index in 0 ..< fetchResult.count {
            photoAssets.append(fetchResult[index])
        }
        
        cachingImageManager.startCachingImages(for: photoAssets, targetSize: CGSize(width: 50.0, height: 50.0), contentMode: .aspectFill, options: nil)
        
        classifiedPhotoAssets = classifyByTimeInterval(photoAssets: photoAssets)
    }
    
    func applyUnarchivedPhotoAssets(unarchivedPhotoAssets: [PHAsset]?) -> [PHAsset]?{
        guard let unarchivedPhotoAssets = unarchivedPhotoAssets else { return nil }
        var removedAssetsFromPhotoLibrary: [PHAsset]? = nil
        
        unarchivedPhotoAssets.forEach {
            guard let unarchivedPhotoAssetsIndex = photoAssets.index(of: $0) else {
                removedAssetsFromPhotoLibrary?.append($0)
                return
            }
            
            photoAssets.remove(at: unarchivedPhotoAssetsIndex)
        }
        
        classifiedPhotoAssets = classifyByTimeInterval(photoAssets: photoAssets)
        
        return removedAssetsFromPhotoLibrary
    }
}

extension PhotoStore: PhotoStoreDelegate {
    func temporaryPhotoDidInserted(insertedPhotoAssets: [PHAsset]) {
        insertedPhotoAssets.forEach {
            guard let index = photoAssets.index(of: $0) else {
                print("This photoAsset is not founded")
                return
            }
            
            photoAssets.remove(at: index)
        }
        
        classifiedPhotoAssets = classifyByTimeInterval(photoAssets: photoAssets)
    }

    func temporaryPhotoDidRemoved(removedPhotoAssets: [PHAsset]) {
        removedPhotoAssets.forEach {
            photoAssets.append($0)
        }
        
        photoAssets.sort { (before, after) in
            guard let beforeCreationDate = before.creationDate,
                let afterCreationDate = after.creationDate else { return false }
            
            return beforeCreationDate > afterCreationDate
        }
        
        classifiedPhotoAssets = classifyByTimeInterval(photoAssets: photoAssets)
    }
}


