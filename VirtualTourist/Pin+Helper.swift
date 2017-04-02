//
//  Pin+Helper.swift
//  VirtualTourist
//
//  Created by pk on 3/10/17.
//  Copyright © 2017 TinyAppsDev. All rights reserved.
//

import Foundation

extension Pin {

    enum State : Int16 {
        case Deleted = -1
        case Created = 0
        case LinksLoading = 1
        case LinksLoaded = 2
    }
    
    func isDownloadCompleted() -> Bool {
        //print("state: \(Pin.State.LinksLoaded.rawValue)")
        //print("count: \(self.downloadedPhotosCount) \(self.photos!.count)")
        
        return self.state == Pin.State.LinksLoaded.rawValue && Int(self.downloadedPhotosCount) == self.photos!.count
    }
    
    func clearPhotos() {
        let photos = self.photos!
        self.photos = NSSet()
        self.downloadedPhotosCount = 0
        for photo in photos {
            if let photo = photo as? Photo, photo.id != nil {
                photo.id = nil
                self.managedObjectContext!.delete(photo)
            }
        }
    }
    
}
