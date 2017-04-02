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
    var pinCommon: PinCommon!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        dataStack = (UIApplication.shared.delegate as! AppDelegate).dataStack
        labelTabPinsToDelete.isHidden = true
        pinCommon = PinCommon(dataStack: dataStack)
        
        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(onLongPressOnMap))
        longPressRecognizer.minimumPressDuration = 0.7
        mapView.addGestureRecognizer(longPressRecognizer)
        
        if let regionData = UserDefaults.standard.dictionary(forKey: "regionData") {
            mapView.setRegion(
                MKCoordinateRegion(
                    center: CLLocationCoordinate2D(
                        latitude: (regionData["latitude"] as! NSNumber).doubleValue,
                        longitude: (regionData["longitude"] as! NSNumber).doubleValue
                    ),
                    span: MKCoordinateSpan(
                        latitudeDelta: (regionData["latitudeDelta"] as! NSNumber).doubleValue,
                        longitudeDelta: (regionData["longitudeDelta"] as! NSNumber).doubleValue
                    )
                ),
                animated: true
            )
        } else {
            locateMe()
        }
        
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
                if pin.state == Pin.State.Created.rawValue || pin.state == Pin.State.LinksLoading.rawValue && pin.stateDate!.timeIntervalSinceNow < -10.0 {
                    pinCommon.fetchPhotosForPin(pin: pin, pageNum: 1, numPerPage: 30)
                    
                } else if pin.state == Pin.State.LinksLoaded.rawValue {
                    pinCommon.reloadIncompletedPhotosForPin(pin: pin)
                    
                }
                
                PhotoAlbumViewController.pushView(self, pin: pin)
            }
        }
    }
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        saveRegionData()
    }
    
    func saveRegionData() {
        let region = mapView.region
        var regionData = [String: Any]()
        
        regionData["latitude"] = NSNumber(value: region.center.latitude)
        regionData["longitude"] = NSNumber(value: region.center.longitude)
        regionData["latitudeDelta"] = NSNumber(value: region.span.latitudeDelta)
        regionData["longitudeDelta"] = NSNumber(value: region.span.longitudeDelta)
        
        UserDefaults.standard.set(regionData, forKey: "regionData")
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
        let pinList = try! dataStack.context.fetch(Pin.fetchRequest()) as! [Pin]
        if let mapView = self.mapView {
            mapView.removeAnnotations(mapView.annotations)
            
            var annotations = [MKAnnotation]()
            for pin in pinList {
                let annotation = MyMKPointAnnotation(pin: pin)
                annotation.coordinate = CLLocationCoordinate2D(
                    latitude: pin.latitude,
                    longitude: pin.longitude
                )
                annotations.append(annotation)
            }
            mapView.addAnnotations(annotations)
        }

    }
    
    func addPin(latitude: Double, longitude: Double) -> Pin {
        let pin = Pin(context: dataStack.context)
        pin.latitude = latitude
        pin.longitude = longitude
        pin.createdDate = NSDate()

        return pin
    }
    
    func delPin(pin: Pin) {
        pin.clearPhotos()
        pin.state = Pin.State.Deleted.rawValue
        dataStack.context.delete(pin)
    }
}

extension MapViewController {

}



