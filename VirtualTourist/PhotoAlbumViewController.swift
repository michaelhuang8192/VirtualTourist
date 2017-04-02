//
//  PhotoAlbumViewController.swift
//  VirtualTourist
//
//  Created by pk on 2/16/17.
//  Copyright © 2017 TinyAppsDev. All rights reserved.
//

import Foundation
import UIKit
import CoreLocation
import MapKit
import CoreData

class PhotoAlbumViewController: UIViewController {
    @IBOutlet weak var mapView : MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var newCollection: UIButton!
    
    var pin: Pin!
    var dataStack: CoreDataStack!
    var pinCommon: PinCommon!
    var emptyImage = UIImage(named: "loading")
    var emptyLabel: UILabel!
    
    var fetchedResultsController : NSFetchedResultsController<NSFetchRequestResult>? {
        didSet {
            fetchedResultsController?.delegate = self
            if let fc = fetchedResultsController {
                do {
                    try fc.performFetch()
                } catch let e as NSError {
                    print("Error while trying to perform a search: \n\(e)\n\(fetchedResultsController)")
                }
            }
            collectionView?.reloadData()
        }
    }
    var _fcChanges = [[Any]]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        newCollection.isEnabled = pin.isDownloadCompleted()
        
        dataStack = (UIApplication.shared.delegate as! AppDelegate).dataStack
        pinCommon = PinCommon(dataStack: dataStack)
        
        let fr: NSFetchRequest<NSFetchRequestResult>  = Photo.fetchRequest()
        fr.sortDescriptors = [
            NSSortDescriptor(key: "id", ascending: true)
        ]
        fr.predicate = NSPredicate(format: "pin = %@", argumentArray: [pin!])
        
        self.fetchedResultsController = NSFetchedResultsController(
            fetchRequest: fr,
            managedObjectContext: self.dataStack.context,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
        
        let coordinate = CLLocationCoordinate2D(latitude: pin.latitude, longitude: pin.longitude)
        
        mapView.setRegion(
            MKCoordinateRegion(
                center: coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
            ),
            animated: true
        )
        
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        mapView.addAnnotation(annotation)
        
        emptyLabel = UILabel(frame: CGRect(x: 0, y: 0, width:0, height:0))
        emptyLabel.textAlignment = .center
        emptyLabel.textColor = UIColor.black
        emptyLabel.text = "No Photo Yet"
    }
    
    @IBAction func onClickNewCollection(_ sender: Any) {
        pin.clearPhotos()
        pinCommon.fetchPhotosForPin(pin: pin, pageNum: 0, numPerPage: 30)
    }
    
    static func pushView(_ callee: UIViewController, pin: Pin) {
        let controller = callee.storyboard!.instantiateViewController(withIdentifier: "PhotoAlbumViewController") as! PhotoAlbumViewController
        controller.pin = pin
        callee.navigationController!.pushViewController(controller, animated: true)
    }
    
}

//Data Fetching
extension PhotoAlbumViewController {
    
}

extension PhotoAlbumViewController : UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let photo = fetchedResultsController!.object(at: indexPath) as! Photo
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoAlbumCell", for: indexPath) as! PhotoAlbumCell
        
        if let imageData = photo.image {
            cell.imageView.image = UIImage(data: imageData as Data)
            cell.activityIndicator.stopAnimating()
        } else {
            cell.imageView.image = emptyImage
            if photo.state == Photo.State.Loading.rawValue {
                cell.activityIndicator.startAnimating()
            } else {
                cell.activityIndicator.stopAnimating()
            }
        }
        
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        var count = 0
        if let fc = fetchedResultsController {
            count = fc.sections![section].numberOfObjects
        }
        
        if count <= 0 {
            emptyLabel.frame.size = collectionView.bounds.size
            collectionView.backgroundView = emptyLabel
        } else {
            collectionView.backgroundView = nil
        }
        
        return count
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        if let fc = fetchedResultsController {
            return (fc.sections?.count)!
        } else {
            return 0
        }
    }
}

extension PhotoAlbumViewController : UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath:IndexPath) {
        let photo = fetchedResultsController!.object(at: indexPath) as! Photo
        photo.delete()
    }
}

extension PhotoAlbumViewController : UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout:UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = collectionView.bounds.width / 3
        return CGSize(width: width, height: width)
    }
}

extension PhotoAlbumViewController : NSFetchedResultsControllerDelegate {
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        self._fcChanges.removeAll()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        _fcChanges.append([0, type, IndexSet(integer: sectionIndex)])
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        _fcChanges.append([1, type, indexPath as Any, newIndexPath as Any])
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {

        collectionView?.performBatchUpdates({
            guard let collectionView = self.collectionView else {
                return
            }
            
            for chg in self._fcChanges {
                if chg[0] as! Int == 0 {
                    switch (chg[1] as! NSFetchedResultsChangeType) {
                    case .insert:
                        collectionView.insertSections(chg[2] as! IndexSet)
                    case .delete:
                        collectionView.deleteSections(chg[2] as! IndexSet)
                    default:
                        break
                    }
                } else {
                    switch(chg[1] as! NSFetchedResultsChangeType) {
                    case .insert:
                        collectionView.insertItems(at: [chg[3] as! IndexPath])
                    case .delete:
                        collectionView.deleteItems(at: [chg[2] as! IndexPath])
                    case .update:
                        collectionView.reloadItems(at: [chg[2] as! IndexPath])
                    case .move:
                        collectionView.deleteItems(at: [chg[2] as! IndexPath])
                        collectionView.insertItems(at: [chg[3] as! IndexPath])
                    }
                }
            }
            
        }, completion: { (_) in
            
        })
        
        newCollection.isEnabled = pin.isDownloadCompleted()
    }
    
}



