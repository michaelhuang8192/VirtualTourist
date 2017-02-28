//
//  MapViewController.swift
//  VirtualTourist
//
//  Created by pk on 2/16/17.
//  Copyright © 2017 TinyAppsDev. All rights reserved.
//

import UIKit
import CoreLocation
import MapKit
import CoreData


class MapViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate {
    @IBOutlet weak var mapView : MKMapView!
    
    @IBOutlet weak var barBtnEdit: UIBarButtonItem!
    @IBOutlet weak var labelTabPinsToDelete: UILabel!
    
    var dataStack: CoreDataStack!
    
    var locationManager : CLLocationManager!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        dataStack = (UIApplication.shared.delegate as! AppDelegate).dataStack
        labelTabPinsToDelete.isHidden = true
        
        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(onLongPressOnMap))
        longPressRecognizer.minimumPressDuration = 0.7
        mapView.addGestureRecognizer(longPressRecognizer)
        
        locateMe()
        
        loadPins()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func onClickBarBtnEdit(_ sender: Any) {
        if !isOnEdit() {
            labelTabPinsToDelete.isHidden = false
            barBtnEdit.title = "Done"
        } else {
            labelTabPinsToDelete.isHidden = true
            barBtnEdit.title = "Edit"
        }
        
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        if let annotation = view.annotation {
            mapView.deselectAnnotation(annotation, animated: false)
            let pin = (annotation as! MyMKPointAnnotation).pin!
            if isOnEdit() {
                mapView.removeAnnotation(annotation)
                delPin(pin: pin)
            } else {
                if pin.state == 0 || pin.state == 1 && pin.stateDate!.timeIntervalSinceNow < -10.0 {
                    fetchPhotosForPin(pin: pin)
                }
                
                PhotoAlbumViewController.pushView(self, pin: pin)
            }
        }
    }
    
    func isOnEdit() -> Bool {
        return !labelTabPinsToDelete.isHidden
    }
    
    func locateMe() {
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager,
                         didUpdateLocations locations: [CLLocation])
    {
        if locationManager == nil { return }
        
        let loc = locations[locations.count - 1]
        locationManager.stopUpdatingLocation()
        locationManager = nil
        
        mapView.setRegion(
            MKCoordinateRegion(
                center: loc.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.2, longitudeDelta: 0.2)
            ),
            animated: true
        )
    }
    
    func onLongPressOnMap(getstureRecognizer : UIGestureRecognizer) {
        if isOnEdit() { return }
        if getstureRecognizer.state != .began { return }
        
        let touchPoint = getstureRecognizer.location(in: mapView)
        let touchMapCoordinate = mapView.convert(touchPoint, toCoordinateFrom: mapView)
        
        let annotation = MyMKPointAnnotation(
            pin: addPin(latitude: touchMapCoordinate.latitude, longitude: touchMapCoordinate.longitude)
        )
        annotation.coordinate = touchMapCoordinate
        
        mapView.addAnnotation(annotation)
    }
    
}


extension MapViewController {
    func loadPins() {
        let asyncRequest = NSAsynchronousFetchRequest(fetchRequest: Pin.fetchRequest()) {
            result -> Void in
            if let mapView = self.mapView {
                mapView.removeAnnotations(mapView.annotations)
                
                var annotations = [MKAnnotation]()
                if let pins = result.finalResult {
                    for pin in pins {
                        let annotation = MyMKPointAnnotation(pin: pin)
                        annotation.coordinate = CLLocationCoordinate2D(
                            latitude: pin.latitude,
                            longitude: pin.longitude
                        )
                        annotations.append(annotation)
                    }
                }
                mapView.addAnnotations(annotations)
            }
        }
        
        try! dataStack.context.execute(asyncRequest)
    }
    
    func addPin(latitude: Double, longitude: Double) -> Pin {
        let pin = Pin(context: dataStack.context)
        pin.latitude = latitude
        pin.longitude = longitude
        pin.createdDate = NSDate()
        
        //fetchPhotosForPin(pin: pin)
        
        return pin
    }
    
    func delPin(pin: Pin) {
        dataStack.context.delete(pin)
    }
}

extension MapViewController {
    
    func fetchPhotosForPin(pin: Pin) {
        pin.state = 1
        pin.stateDate = NSDate()
        
        Flickr.shared.getPhotosByGeo(latitude: pin.latitude, longitude: pin.longitude) { (error, photos) in
            DispatchQueue.main.async {
                if error != nil {
                    pin.state = 0
                } else {
                    self.addPhotosForPin(pin: pin, photos: photos!)
                    pin.state = 2
                }
            }
        }
    }
    
    func addPhotosForPin(pin: Pin, photos: [[String: Any]]) {
        var urlList = [String]()
        var ctxList = [Any]()
        for p in photos {
            let photo = Photo(context: self.dataStack.context)
            photo.title = p["title"] as? String
            photo.url = p["url"] as? String
            photo.id = p["id"] as? String
            pin.addToPhotos(photo)
            
            urlList.append(photo.url!)
            ctxList.append(photo.objectID)
        }
        
        if !urlList.isEmpty {
            PhotoDownloader.shared.download(
                urlList: urlList,
                ctxList: ctxList,
                onComplete: onCompleted
            )
            print(">>add download - count:\(urlList.count)")
        }
    }
    
    func onCompleted(_ data: Data?, _ ctx: Any) -> Void {
        let objectId = ctx as! NSManagedObjectID
        dataStack.performBackgroundBatchOperation { (ctx) in
            if let photo = ctx.object(with: objectId) as? Photo {
                photo.image = data as NSData?
            }
        }
    }
    
}



