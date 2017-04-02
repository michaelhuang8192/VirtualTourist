//
//  CoreDataCollectionViewController.swift
//
//
//  Created by Fernando Rodríguez Romero on 22/02/16.
//  Copyright © 2016 udacity.com. All rights reserved.
//

import UIKit
import CoreData

// MARK: - CoreDataTableViewController: UITableViewController

class CoreDataCollectionViewController: UICollectionViewController {
    
    var _fcChanges = [[Any]]()
    
    // MARK: Properties
    
    var fetchedResultsController : NSFetchedResultsController<NSFetchRequestResult>? {
        didSet {
            // Whenever the frc changes, we execute the search and
            // reload the table
            fetchedResultsController?.delegate = self
            executeSearch()
            collectionView?.reloadData()
        }
    }
    
}

// MARK: - CoreDataTableViewController (Subclass Must Implement)

extension CoreDataCollectionViewController {
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        fatalError("This method MUST be implemented by a subclass of CoreDataTableViewController")
    }
}

// MARK: - CoreDataTableViewController (Table Data Source)

extension CoreDataCollectionViewController {
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        if let fc = fetchedResultsController {
            return (fc.sections?.count)!
        } else {
            return 0
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let fc = fetchedResultsController {
            return fc.sections![section].numberOfObjects
        } else {
            return 0
        }
    }
}

// MARK: - CoreDataTableViewController (Fetches)

extension CoreDataCollectionViewController {
    
    func executeSearch() {
        if let fc = fetchedResultsController {
            do {
                try fc.performFetch()
            } catch let e as NSError {
                print("Error while trying to perform a search: \n\(e)\n\(fetchedResultsController)")
            }
        }
    }
}

// MARK: - CoreDataTableViewController: NSFetchedResultsControllerDelegate

extension CoreDataCollectionViewController: NSFetchedResultsControllerDelegate {
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        
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
            self._fcChanges.removeAll()
            
        })
        
    }
}

