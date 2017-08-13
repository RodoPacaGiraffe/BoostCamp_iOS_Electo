//
//  PhotoViewController.swift
//  Electo
//
//  Created by RodoPacaGiraffe on 2017. 8. 4..
//  Copyright © 2017년 RodoPacaGiraffe. All rights reserved.
//

import UIKit
import Photos

class ClassifiedPhotoViewController: UIViewController {
    //MARK: Properties
    @IBOutlet var tableView: UITableView!
    
    var photoDataSource: PhotoDataSource = PhotoDataSource()
    let loadingView = LoadingView.instanceFromNib()
    var originalTabBarFrame: CGRect = CGRect()
    var timer: Timer?
    var time: TimeInterval = 0 {
        didSet {
            if time == Constants.loadingTime {
                stopTimer()
                disappearLoadingView()
            }
        }
    }
    
    //MARK: Functions
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.dataSource = photoDataSource
        
        if let tabBarFrame = self.tabBarController?.tabBar.frame {
            originalTabBarFrame = tabBarFrame
        }
        
        appearLoadingView()
        requestAuthorization()
        
        NotificationCenter.default.addObserver(self, selector: #selector (reloadData),
                                               name: Constants.requiredReload, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        tableView.reloadData()
        self.tabBarController?.tabBar.isHidden = false
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func appearLoadingView() {
        timer = Timer.scheduledTimer(withTimeInterval: Constants.loadingTime, repeats: false) {
            [weak self] (timer: Timer) in
            
            self?.time += timer.timeInterval
        }
        
        self.view.addSubview(loadingView)
        self.navigationController?.navigationBar.isHidden = true
        self.tabBarController?.tabBar.frame = CGRect(x: 0, y: 0, width: 0, height: 0)
    }
    
    private func disappearLoadingView() {
        self.loadingView.stopIndicatorAnimating()
        self.loadingView.removeFromSuperview()
    
        self.navigationController?.navigationBar.isHidden = false
        self.tabBarController?.tabBar.frame = originalTabBarFrame
        
        tableView.reloadData()
    }
    
    private func requestAuthorization() {
        PHPhotoLibrary.requestAuthorization {
            [weak self] (authorizationStatus) -> Void in
            guard authorizationStatus == .authorized else { return }
            
            self?.photoDataSource.photoStore.fetchPhotoAsset()
            

            DispatchQueue.global().sync {
                guard let archivedtemporaryPhotoStore = NSKeyedUnarchiver.unarchiveObject(withFile: path)
                    as? TemporaryPhotoStore else { return }
                
                self?.photoDataSource.temporaryPhotoStore = archivedtemporaryPhotoStore
                self?.photoDataSource.temporaryPhotoStore.fetchPhotoAsset()
    
                let unarchivedPhotoAssets = self?.photoDataSource.temporaryPhotoStore.photoAssets
                
                let removedAssetsFromLibrary = self?.photoDataSource.photoStore.applyUnarchivedPhoto(
                    assets: unarchivedPhotoAssets)
                
                if let photoAssets = removedAssetsFromLibrary {
                    self?.photoDataSource.temporaryPhotoStore.remove(
                        photoAssets: photoAssets, isPerformDelegate: false)
                }
                
                DispatchQueue.main.async {
                    self?.tableView.reloadData()
                }
            }

        }
    }
    
    private func fetchArchivedTemporaryPhotoStore() {
        guard let path = Constants.archiveURL?.path else { return }
        
        DispatchQueue.global().async {
            [weak self] in
            guard let archivedtemporaryPhotoStore = NSKeyedUnarchiver.unarchiveObject(withFile: path)
                as? TemporaryPhotoStore else { return }
            
            self?.photoDataSource.temporaryPhotoStore = archivedtemporaryPhotoStore
            self?.photoDataSource.temporaryPhotoStore.fetchPhotoAsset()
            
            let unarchivedPhotoAssets = self?.photoDataSource.temporaryPhotoStore.photoAssets
            
            let removedAssetsFromLibrary = self?.photoDataSource.photoStore.applyUnarchivedPhotoAssets(unarchivedPhotoAssets: unarchivedPhotoAssets)
            
            if let photoAssets = removedAssetsFromLibrary {
                self?.photoDataSource.temporaryPhotoStore.remove(
                    photoAssets: photoAssets, isPerformDelegate: false)
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard segue.identifier == "ModalRemovedPhotoVC" else { return }
        guard let navigationController = segue.destination as? UINavigationController,
            let temporaryPhotoViewController = navigationController.topViewController
                as? TemporaryPhotoViewController else { return }
        
        temporaryPhotoViewController.photoDataSource = photoDataSource

    }
    
    func reloadData() {
        DispatchQueue.main.async { [weak self] in
            self?.tableView.reloadData()
        }

    }
}

extension ClassifiedPhotoViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let photoCell = cell as? ClassifiedPhotoCell else {
            print("cell is not a photoCell")
            return
        }
        
        photoCell.clearStackView()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let detailViewController = storyboard?.instantiateViewController(withIdentifier:  "detailViewController") as? DetailPhotoViewController else { return }
        detailViewController.selectedSection = indexPath.section
        detailViewController.photoStore = photoDataSource.photoStore
        
        detailViewController.identifier = "fromClassifiedView"
        let selectedCell = tableView.cellForRow(at: indexPath) as? ClassifiedPhotoCell ?? ClassifiedPhotoCell.init()
        detailViewController.thumbnailImages = selectedCell.cellImages
        detailViewController.pressedIndexPath = IndexPath(row: 0, section: 0)
        
        show(detailViewController, sender: self)
        
        
    }
}


