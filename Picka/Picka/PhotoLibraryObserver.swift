//
//  PhotoLibraryObserver.swift
//  Electo
//
//  Created by RodoPacaGiraffe on 2017. 8. 13..
//  Copyright © 2017년 RodoPacaGiraffe. All rights reserved.
//

import Foundation
import Photos

class PhotoLibraryObserver: NSObject, PHPhotoLibraryChangeObserver {    
    private var fetchResult: PHFetchResult<PHAsset>?
    static let shared: PhotoLibraryObserver = PhotoLibraryObserver()
    
    override init() {
        super.init()
        
        PHPhotoLibrary.shared().register(self)
    }
    
    deinit {
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
    }
    
    func setObserving(fetchResult: PHFetchResult<PHAsset>) {
        self.fetchResult = fetchResult
    }
    
    func photoLibraryDidChange(_ changeInstance: PHChange) {
        guard let fetchResult = fetchResult,
            let changeDetail = changeInstance.changeDetails(for: fetchResult) else { return }
        
        let removedPhotoAssets = [NotificationUserInfoKey.removedPhotoAssets: changeDetail.removedObjects]
        
        NotificationCenter.default.post(name: NotificationName.removedAssetsFromPhotoLibrary,
                                        object: nil, userInfo: removedPhotoAssets)
    }
}
