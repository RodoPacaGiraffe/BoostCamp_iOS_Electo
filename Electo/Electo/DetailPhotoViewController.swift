//
//  DetailViewController.swift
//  Electo
//
//  Created by byung-soo kwon on 2017. 8. 8..
//  Copyright © 2017년 RodoPacaGiraffe. All rights reserved.
//

import UIKit
import Photos

class DetailPhotoViewController: UIViewController {
    
    @IBOutlet var zoomingScrollView: UIScrollView!
    @IBOutlet var detailImageView: UIImageView!
    @IBOutlet var thumbnailCollectionView: UICollectionView!
    @IBOutlet var loadingIndicatorView: UIActivityIndicatorView!
    @IBOutlet var flowLayout: UICollectionViewFlowLayout!
    var moveToTempVCButtonItem: UIBarButtonItem?
    
    var thumbnailImages: [UIImage] = .init()
    var selectedSectionAssets: [PHAsset] = []
    var photoDataSource: PhotoDataSource?
    var pressedIndexPath: IndexPath = IndexPath()
    var selectedPhotos: Int = 0
    var previousSelectedCell: DetailPhotoCell?
    var identifier: String = ""
    var startPanGesturePoint: CGPoint = CGPoint()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setFlowLayout()
        displayDetailViewSetting()
        setNavigationButtonItem()
        
        NotificationCenter.default.addObserver(self, selector: #selector (applyRemovedAssets(_:)),
                                               name: Constants.removedAssetsFromPhotoLibrary, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: Constants.requiredReload, object: nil)
    }
    
    @objc func applyRemovedAssets(_ notification: Notification) {
        guard let removedPhotoAssets = notification.userInfo?[Constants.removedPhotoAssets]
            as? [PHAsset] else { return }
        
        removedPhotoAssets.forEach {
            guard let index = selectedSectionAssets.index(of: $0) else {
                print("This photoAsset is not founded from DetailVC")
                return
            }
            
            selectedSectionAssets.remove(at: index)
        }
        
        DispatchQueue.main.async { [weak self] in
            self?.thumbnailCollectionView.reloadSections(IndexSet(integer: 0))
            self?.moveToNextPhoto()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {   
        guard let count = photoDataSource?.temporaryPhotoStore.photoAssets.count else { return }
        moveToTempVCButtonItem?.updateBadge(With: count)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        detailImageView.layer.removeAllAnimations()
    }
    
    private func setFlowLayout() {
        flowLayout.itemSize.height = thumbnailCollectionView.bounds.height
        flowLayout.itemSize.width = flowLayout.itemSize.height
        if identifier == "fromTemporaryViewController" {
            navigationItem.setRightBarButtonItems(nil, animated: false)
        }
    }
    
    private func updatePhotoIndex(direction: UISwipeGestureRecognizerDirection) {
        switch direction {
        case UISwipeGestureRecognizerDirection.right:
            selectedPhotos -= 1
            if selectedPhotos < 0 {
                selectedPhotos += 1
            }
        case UISwipeGestureRecognizerDirection.left:
            let count = selectedSectionAssets.count

            selectedPhotos += 1
            if selectedPhotos == count {
                selectedPhotos -= 1
            }
        default:
            break
        }
    }
    
    private func displayDetailViewSetting() {
        self.zoomingScrollView.minimumZoomScale = 1.0
        self.zoomingScrollView.maximumZoomScale = 6.0
        
        detailImageView.image = thumbnailImages.first
        
        fetchFullSizeImage(from: pressedIndexPath)
        thumbnailCollectionView.selectItem(at: pressedIndexPath, animated: true, scrollPosition: .centeredHorizontally)
    }
    
    private func setTranslucentToNavigationBar() {
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.isTranslucent = true
    }
    
    private func setNavigationButtonItem() {
        guard let count = photoDataSource?.temporaryPhotoStore.photoAssets.count else { return }
        
        moveToTempVCButtonItem = UIBarButtonItem.getUIBarbuttonItemincludedBadge(With: count)
        
        moveToTempVCButtonItem?.addButtonTarget(target: self,
                                                action: #selector (moveToTemporaryViewController),
                                                for: .touchUpInside)
        
        self.navigationItem.setRightBarButton(moveToTempVCButtonItem, animated: true)
    }
    
    @objc private func moveToTemporaryViewController() {
        performSegue(withIdentifier: "ModalRemovedPhotoVC", sender: self)
    }
    
    func fetchFullSizeImage(from indexPath: IndexPath) {
        let options = PHImageRequestOptions()
        options.setImageRequestOptions(networkAccessAllowed: true, synchronous: false, deliveryMode: .opportunistic) { [weak self] (progress, _, _, _)-> Void in
            DispatchQueue.main.async {
                guard let thumbnailViewCell = self?.thumbnailCollectionView.cellForItem(at: indexPath) as? DetailPhotoCell else { return }

                guard self?.pressedIndexPath == indexPath else { return }
                self?.detailImageView.image = thumbnailViewCell.thumbnailImageView.image
                self?.loadingIndicatorView.startAnimating()
                
                let percent = 100 * progress
                let progressView: UIProgressView = .init()
                progressView.progressViewStyle = .bar
                progressView.tintColor = UIColor.black
                
                progressView.frame = CGRect.init(x: (self?.detailImageView.center.x)! - 100, y: (self?.detailImageView.center.y)!, width: 250, height: 250)
                self?.detailImageView.addSubview(progressView)
                
                progressView.setProgress(Float(percent), animated: true)
            }
        }
        
        let photoAsset: PHAsset = selectedSectionAssets[indexPath.item]
        DispatchQueue.global().async { [weak self] _ -> Void in
            photoAsset.fetchFullSizeImage(options: options, resultHandler: { [weak self] (fetchedData) in
                guard let data = fetchedData else { return }
                DispatchQueue.main.async {
                    guard self?.pressedIndexPath == indexPath else { return }
                    self?.detailImageView.image = UIImage(data: data)
                    self?.loadingIndicatorView.stopAnimating()
                }
            })
        }
    }

    @IBAction func horizontalSwipeAction(_ sender: UISwipeGestureRecognizer) {
        updatePhotoIndex(direction: sender.direction)
        
        let index = IndexPath(row: selectedPhotos, section: 0)
        
        collectionView(thumbnailCollectionView, didSelectItemAt: index)
        thumbnailCollectionView.selectItem(at: index, animated: true, scrollPosition: .centeredHorizontally)
    }
    
    func moveToNextPhoto() {
        guard !selectedSectionAssets.isEmpty else {
            self.navigationController?.popViewController(animated: true)
            return
        }
        
        if selectedPhotos >= selectedSectionAssets.count - 1 {
            updatePhotoIndex(direction: .right)
        }
        let index = IndexPath(row: selectedPhotos, section: 0)
        
        collectionView(thumbnailCollectionView, didSelectItemAt: index)
        thumbnailCollectionView.selectItem(at: index, animated: true, scrollPosition: .centeredHorizontally)
    }
    
    @IBAction func panGestureAction(_ sender: UIPanGestureRecognizer) {

        let location = sender.translation(in: self.view)
        
        switch sender.state {
        case .began:
            startPanGesturePoint = location
            setTranslucentToNavigationBar()
        case .ended:
            guard (startPanGesturePoint.y - location.y) > view.bounds.height / 6 else {
                
                self.navigationController?.navigationBar.setBackgroundImage(nil, for: .default)
                self.navigationController?.navigationBar.isTranslucent = false
                
                detailImageView.center = CGPoint(x: zoomingScrollView.center.x,
                                                 y: zoomingScrollView.center.y)
                break
            }
        
            moveToTrashAnimation()
        case .changed:
            detailImageView.frame.origin.y = location.y
        default:
            break
        }
      
    }
    
    private func moveToTrashAnimation() {
        guard let naviBarHeight = self.navigationController?.navigationBar.bounds.height else { return }
        
        let targetY = -(naviBarHeight / 2)
        let targetX = thumbnailCollectionView.bounds.width
        
        UIView.animate(withDuration: 0.2,
        animations: { [weak self] in
            guard let detailVC = self else { return }
            detailVC.detailImageView.center = CGPoint(x: targetX, y: targetY)
            detailVC.detailImageView.transform = CGAffineTransform(scaleX: 0.001, y: 0.001)
        }, completion: { [weak self] _ in
            guard let detailVC = self else { return }
            detailVC.navigationController?.navigationBar.isTranslucent = false
            detailVC.navigationController?.navigationBar.setBackgroundImage(nil, for: .default)
            
            detailVC.photoDataSource?.temporaryPhotoStore.insert(
                photoAssets: [detailVC.selectedSectionAssets[detailVC.selectedPhotos]])
            
            guard let count = detailVC.photoDataSource?.temporaryPhotoStore.photoAssets.count else { return }
            
            detailVC.moveToTempVCButtonItem?.updateBadge(With: count)

            detailVC.selectedSectionAssets.remove(at: detailVC.selectedPhotos)
            
            detailVC.detailImageView.center = detailVC.zoomingScrollView.center
            detailVC.detailImageView.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
            
            detailVC.thumbnailCollectionView.reloadSections(IndexSet(integer: 0))
            
            detailVC.moveToNextPhoto()
        })
    }
    
    @IBAction func doubleTap(_ sender: UITapGestureRecognizer) {
        self.zoomingScrollView.setZoomScale(1.0, animated: true)
        self.detailImageView.contentMode = .scaleAspectFill
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard segue.identifier == "ModalRemovedPhotoVC" else { return }
        guard let navigationController = segue.destination as? UINavigationController,
            let temporaryPhotoViewController = navigationController.topViewController
                as? TemporaryPhotoViewController else { return }
        
        temporaryPhotoViewController.photoDataSource = photoDataSource
    }
    
}

extension DetailPhotoViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return selectedSectionAssets.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "detailPhotoCell", for: indexPath) as? DetailPhotoCell ?? DetailPhotoCell()
        
        if previousSelectedCell == nil {
            cell.select()
            previousSelectedCell = cell
        } else if let selectedItems = collectionView.indexPathsForSelectedItems,
            selectedItems.contains(indexPath) {
            cell.select()
        } else {
            cell.deSelect()
        }
        
        let photoAssets = selectedSectionAssets
        let photoAsset = photoAssets[indexPath.item]
        
        if let previousRequestID = cell.requestID {
            let manager = PHImageManager.default()
            manager.cancelImageRequest(previousRequestID)
        }
        
        cell.requestID = photoAsset.fetchImage(size: Constants.fetchImageSize,
                                               contentMode: .aspectFill,
                                               options: nil,
                                               resultHandler: { (requestedImage) in
                                                cell.thumbnailImageView.image = requestedImage
        })
        
        return cell
    }
}

extension DetailPhotoViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let thumbnailViewCell = collectionView.cellForItem(at: indexPath)
            as? DetailPhotoCell else { return }
    
        previousSelectedCell?.deSelect()
        
        thumbnailViewCell.select()
        previousSelectedCell = thumbnailViewCell
        self.pressedIndexPath = indexPath
        self.detailImageView.contentMode = .scaleAspectFill
        self.zoomingScrollView.setZoomScale(1.0, animated: true)

        selectedPhotos = indexPath.item
        fetchFullSizeImage(from: indexPath)
    }
}

extension DetailPhotoViewController: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return self.detailImageView
    }
    
    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        self.zoomingScrollView.setZoomScale(1.0, animated: true)
    }
}

extension DetailPhotoViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        otherGestureRecognizer.require(toFail: gestureRecognizer)
        return true
    }
}
