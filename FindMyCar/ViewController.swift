//
//  ViewController.swift
//  FindMyCar
//
//  Created by jhchoi on 09/08/2018.
//  Copyright © 2018 EX2I. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import Contacts

class ViewController: UIViewController, CLLocationManagerDelegate {
    var beacons = [String:[CLBeacon]]()
    var locationManager = CLLocationManager()
    var rangedRegions = [CLBeaconRegion]()
    var proximityBeacons : [AnyObject]?
    
    @IBOutlet weak var mapView: MKMapView!
    
    let regionRadius : CLLocationDistance = 10

    @IBOutlet weak var distanceLabel: UILabel!
    
    @IBOutlet weak var statusLabel: UILabel!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let supportedProximityUUIDs = UUID(uuidString: "54DDF411-8CF1-440C-87CD-E368DAF9C93A")
        let region = CLBeaconRegion(proximityUUID: supportedProximityUUIDs!, major: 501, minor: 12654, identifier: (supportedProximityUUIDs?.uuidString)!)
        
        rangedRegions.append(region)

        locationManager.delegate = self
        locationManager.requestAlwaysAuthorization()
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        
        mapView.delegate = self
        mapView.showsUserLocation = true
        
        statusLabel.text = "__"
        distanceLabel.text = "__"
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        locationManager.startUpdatingLocation()
        
        for (region) in locationManager.monitoredRegions {
            locationManager.stopMonitoring(for: region as! CLBeaconRegion)
        }
        
        for (region) in locationManager.rangedRegions {
            locationManager.stopRangingBeacons(in: region as! CLBeaconRegion)
        }

        for (region) in rangedRegions {
            region.notifyOnEntry = true
            region.notifyOnExit = true
            
            locationManager.startMonitoring(for: region)
            locationManager.startRangingBeacons(in: region)
            locationManager.requestState(for: region)
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        locationManager.stopUpdatingLocation()
        
        for (region) in locationManager.monitoredRegions {
            locationManager.stopMonitoring(for: region as! CLBeaconRegion)
        }
        
        for (region) in locationManager.rangedRegions {
            locationManager.stopRangingBeacons(in: region as! CLBeaconRegion)
        }
    }
    
    @IBAction func start(_ sender: Any) {
        if mapView.annotations.count > 1 {
            let alert = UIAlertController(title: "확인",
                                          message: "주차 위치를 변경 하시겠습니까",
                                          preferredStyle: UIAlertControllerStyle.alert)

            alert.addAction(UIAlertAction(title: "확인",
                                          style: UIAlertActionStyle.default,
                                          handler: {(alert: UIAlertAction!) in
                                            self.parkCar()
            }))
            
            alert.addAction(UIAlertAction(title: "취소",
                                          style: UIAlertActionStyle.default,
                                          handler: {(alert: UIAlertAction!) in
                                            return
            }))
            
            self.present(alert, animated: true) {
                
            }
        } else {
            self.parkCar()
        }
    }
    
    func parkCar() {
        for i in self.mapView.annotations {
            self.mapView.removeAnnotation(i)
        }
        
        let artwork = Artwork(title: "내 자동차",
                              locationName: "내 자동차 위치",
                              discipline: "테스트",
                              coordinate: CLLocationCoordinate2D(latitude: (self.locationManager.location?.coordinate.latitude)!, longitude: (self.locationManager.location?.coordinate.longitude)!))
        self.mapView.addAnnotation(artwork)
    }
    
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        macpCenter()
    }
    
    func macpCenter() {
        let userLocation = mapView.userLocation
        centerMapOnLocation(location: userLocation.location!)
    }
    
    func centerMapOnLocation(location: CLLocation) {
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(location.coordinate,
                                                                  regionRadius, regionRadius)
        mapView.setRegion(coordinateRegion, animated: true)
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    }
    
    
    func locationManager(_ manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], in region: CLBeaconRegion) {
        self.beacons.removeAll(keepingCapacity: false)
        
        for indBeacon in beacons {
            
            switch indBeacon.proximity.rawValue {
                
            case CLProximity.immediate.rawValue:
                parkCar()

                let distance = round(indBeacon.accuracy * 100.0) / 100.0
                distanceLabel.text = "\(String(distance)) m"
                
            case CLProximity.far.rawValue, CLProximity.near.rawValue:
                let distance = round(indBeacon.accuracy * 100.0) / 100.0
                distanceLabel.text = "\(String(distance)) m"
            case CLProximity.unknown.rawValue: break
            default:
                print("") // do nothing
            }
        }
        
    }
    
    func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
        print(region ?? "error")
    }
    
    func locationManager(_ manager: CLLocationManager, rangingBeaconsDidFailFor region: CLBeaconRegion, withError error: Error) {
        print(region)
    }
    
    func locationManager(_ manager: CLLocationManager, didStartMonitoringFor region: CLRegion) {
        statusLabel.text = "mornitoring start"
    }
    
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        statusLabel.text = "이탈"
    }
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        statusLabel.text = "도착"
    }
    
    func locationManager(_ manager: CLLocationManager, didDetermineState state: CLRegionState, for region: CLRegion) {
        //
        switch state {
            
        case CLRegionState.inside:
            statusLabel.text = "진입중"
            
        case CLRegionState.outside:
            statusLabel.text = "멀어지는중"
            
        default:
            statusLabel.text = "알수없는상태"
        }
    }
}

class Artwork: NSObject, MKAnnotation {
    let title: String?
    let locationName: String
    let discipline: String
    let coordinate: CLLocationCoordinate2D
    
    init(title: String, locationName: String, discipline: String, coordinate: CLLocationCoordinate2D) {
        self.title = title
        self.locationName = locationName
        self.discipline = discipline
        self.coordinate = coordinate
        
        super.init()
    }
    
    var subtitle: String? {
        return locationName
    }
}

extension ViewController: MKMapViewDelegate {
    // 1
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        // 2
        guard let annotation = annotation as? Artwork else { return nil }
        // 3
        let identifier = "marker"
        var view: MKMarkerAnnotationView
        // 4
        if let dequeuedView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
            as? MKMarkerAnnotationView {
            dequeuedView.annotation = annotation
            view = dequeuedView
        } else {
            // 5
            view = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            view.canShowCallout = true
            view.calloutOffset = CGPoint(x: -5, y: 5)
            view.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
        }
        return view
    }
}

