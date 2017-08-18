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
    
    @IBOutlet var leftGesture: UISwipeGestureRecognizer!
    @IBOutlet var rightGesture: UISwipeGestureRecognizer!
    @IBOutlet var panGesture: UIPanGestureRecognizer!
    @IBOutlet var zoomingScrollView: UIScrollView!
    @IBOutlet var detailImageView: UIImageView!
    @IBOutlet var thumbnailCollectionView: UICollectionView!
    @IBOutlet var loadingIndicatorView: UIActivityIndicatorView!
    @IBOutlet var flowLayout: UICollectionViewFlowLayout!
    var moveToTempVCButtonItem: UIBarButtonItem?
    
    var thumbnailImages: [UIImage] = .init()
    var selectedSectionAssets: [PHAsset] = []
    var selectedSection: Int = 0
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
    }
    
    override func viewWillAppear(_ animated: Bool) {   
        guard let count = photoDataSource?.temporaryPhotoStore.photoAssets.count else { return }
        moveToTempVCButtonItem?.updateBadge(With: count)
    }
    
    private func setFlowLayout() {
        flowLayout.itemSize.height = thumbnailCollectionView.bounds.height
        flowLayout.itemSize.width = flowLayout.itemSize.height
        if identifier == "fromTemporaryViewController" {
            navigationItem.setRightBarButtonItems(nil, animated: false)
        }
    }

    
    func getAsset(from identifier: String) -> [PHAsset] {
        switch identifier {
        case "fromTemporaryViewController":
            return selectedSectionAssets
        default:
            return selectedSectionAssets
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
            let count = getAsset(from: identifier).count

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
        
        self.tabBarController?.tabBar.isHidden = true
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
        animations: {
            self.detailImageView.center = CGPoint(x: targetX, y: targetY)
            self.detailImageView.transform = CGAffineTransform(scaleX: 0.001, y: 0.001)
        }, completion: { _ in

            self.navigationController?.navigationBar.isTranslucent = false
            self.photoDataSource?.temporaryPhotoStore.insert(photoAssets: [self.getAsset(from: self.identifier)[self.selectedPhotos]])
            
            self.selectedSectionAssets.remove(at: self.selectedPhotos)
            
            self.navigationController?.navigationBar.setBackgroundImage(nil, for: .default)
            
            self.detailImageView.center = self.zoomingScrollView.center
            self.detailImageView.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
            
            self.thumbnailCollectionView.reloadSections(IndexSet(integer: 0))
            self.moveToNextPhoto()
        })
    }

    @IBAction func screenEdgePan(_ sender: UIScreenEdgePanGestureRecognizer) {
        print("edge")
        dismiss(animated: true, completion: nil)
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
        let storeAssetsCount = getAsset(from: identifier).count
        return storeAssetsCount
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "detailPhotoCell", for: indexPath) as? DetailPhotoCell ?? DetailPhotoCell()
        
        let photoAssets = self.getAsset(from: identifier)
        let photoAsset = photoAssets[indexPath.item]
        let options = PHImageRequestOptions()
        
        if let previousRequestID = cell.requestID {
            let manager = PHImageManager.default()
            manager.cancelImageRequest(previousRequestID)
        }
        
        cell.requestID = photoAsset.fetchImage(size: Constants.fetchImageSize,
                                               contentMode: .aspectFill,
                                               options: options,
                                               resultHandler: { (requestedImage) in
                                                cell.thumbnailImageView.image = requestedImage
        })
        
        if previousSelectedCell == nil {
            cell.select()
            previousSelectedCell = cell
        }
        
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
