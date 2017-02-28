//
//  MyAnnotation.swift
//  VirtualTourist
//
//  Created by pk on 2/24/17.
//  Copyright © 2017 TinyAppsDev. All rights reserved.
//

import Foundation
import MapKit


class MyMKPointAnnotation : MKPointAnnotation {
    var pin: Pin!
    
    init(pin: Pin) {
        super.init()
        self.pin = pin
    }
}
