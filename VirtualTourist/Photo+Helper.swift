//
//  Photo+Helper.swift
//  VirtualTourist
//
//  Created by pk on 3/10/17.
//  Copyright © 2017 TinyAppsDev. All rights reserved.
//

import Foundation

extension Photo {
    
    enum State : Int16 {
        case Deleted = -1
        case Created = 0
        case Loading = 1
        case Loaded = 2
    }
    
    func delete() {
        if self.id != nil, let context = self.managedObjectContext {
            self.state = State.Deleted.rawValue
            self.id = nil
            if self.image != nil {
                self.pin?.downloadedPhotosCount -= 1
            }
            context.delete(self)
        }
    }
    
    func setImage(imageData: NSData) {
        if self.id != nil {
            if self.image != nil {
                self.pin?.downloadedPhotosCount -= 1
            }
            self.image = imageData
            if self.image != nil {
                self.pin?.downloadedPhotosCount += 1
            }
        }
    }
}
