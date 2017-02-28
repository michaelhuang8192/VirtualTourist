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
    
    var pin: Pin!
    var dataStack: CoreDataStack!
    
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
    
    func onCompleted(_ data: Data?, _ ctx: Any) -> Void {
        let objectId = ctx as! NSManagedObjectID
        dataStack.performBackgroundBatchOperation { (ctx) in
            if let photo = ctx.object(with: objectId) as? Photo {
                photo.image = data as NSData?
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        dataStack = (UIApplication.shared.delegate as! AppDelegate).dataStack
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
        } else {
            cell.imageView.image = UIImage(named: "loading")
        }
        
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let fc = fetchedResultsController {
            return fc.sections![section].numberOfObjects
        } else {
            return 0
        }
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
        
    }
    
}



