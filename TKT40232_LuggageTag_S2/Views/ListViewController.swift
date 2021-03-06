//
//  ViewController.swift
//  TKT40214_LuggageFinder_S1_iOS
//
//  Created by PhTktimac1 on 24/05/2016.
//  Copyright © 2016 Tektos Limited. All rights reserved.
//

import UIKit
import CoreBluetooth
import CoreLocation
import CoreData

struct Drag {
    static var placeholderView: UIView!
    static var sourceIndexPath: IndexPath!
}

var beaconLuggageReference: [LuggageTag]?

class ListViewController: UIViewController, CBCentralManagerDelegate, TKTCoreLocationDelegate, UITableViewDataSource,
UITableViewDelegate, BeaconDetailViewControllerDelegate, NSFetchedResultsControllerDelegate, CustomTableCellDelegate, UIPageViewControllerDelegate {
    
    var row: [LuggageTag]
    let moc = (UIApplication.shared.delegate as! AppDelegate).managedObjectContext
    
    var frc: NSFetchedResultsController<BeaconItem>  = NSFetchedResultsController()
    
    @IBOutlet var tableView: UITableView!
    @IBOutlet weak var appLogo: UIImageView!
    @IBOutlet weak var appInfoView: UIView!
    @IBOutlet weak var versionLabel: UILabel!
    @IBOutlet weak var companyLabel: UILabel!
    @IBOutlet weak var rightsLabel: UILabel!
    
    var centralManager: CBCentralManager!
    
    var tktCoreLocation: TKTCoreLocation!
    
    var isBluetoothPoweredOn: Bool = false
    var isMonitoring: Bool = false
    
    
    // MARK: CoreData Fetching Methods
    func fetchRequest() -> NSFetchRequest<BeaconItem> {
        let request: NSFetchRequest<BeaconItem> = NSFetchRequest(entityName: "BeaconItem")
        let sortDescriptor = NSSortDescriptor(key: "id", ascending: true)
        request.sortDescriptors = [sortDescriptor]
        
        return request
    }
    
    func getFRC() -> NSFetchedResultsController<BeaconItem> {
        frc = NSFetchedResultsController(fetchRequest: fetchRequest(), managedObjectContext: moc, sectionNameKeyPath: nil, cacheName: nil)
        
        return frc
    }
    
    required init?(coder aDecoder: NSCoder) {
        row = [LuggageTag]()
        super.init(coder: aDecoder)
    }
    
    // MARK: Override Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        formatNavigationBar()
        applicationInfo()
        
        centralManager = CBCentralManager(delegate: self, queue: nil)
        tktCoreLocation = TKTCoreLocation(delegate: self)
        
        frc = getFRC()
        frc.delegate = self
        
        do {
            try frc.performFetch()
            loadBeaconItems()
        } catch {
            Globals.log("Failed to perform initial fetch.")
        }
        
        // Add LongPress Gesture in our TableView
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(ListViewController.longPressGestureRecognized(_:)))
        tableView.addGestureRecognizer(longPress)
        
        // Add NSNotificationCenter Observer for this Controller
        NotificationCenter.default.addObserver(self, selector: #selector(ListViewController.setBattery(_:)), name: NSNotification.Name(rawValue: Constants.Notification.SetBattery), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(ListViewController.setLuggageImageRange(_:)), name: NSNotification.Name(rawValue: Constants.Notification.SetImageRange), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(ListViewController.transmitActivationKey(_:)), name: NSNotification.Name(rawValue: Constants.Notification.TransmitActivationKey), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(ListViewController.SavingNewLugguageItem(_:)), name: NSNotification.Name(rawValue: Constants.Notification.SavingNewLugguageItem), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(ListViewController.didShowBluetoothState(_:)), name: NSNotification.Name(rawValue: "ShowBluetoothState"), object: nil)
        
    }
    
    func setBattery(_ notification: Notification) {
        let key = (notification as NSNotification).userInfo!["key"] as! String
        let percentage = "\((notification as NSNotification).userInfo!["minor"] as! Int)"
        let rowIndex = getObjectIndex(key)
        
        if (row[rowIndex].minor != percentage) {
            let indexPath = IndexPath(row: rowIndex, section: 0)
            row[rowIndex].minor = percentage
            
            if let cell = tableView.cellForRow(at: indexPath) {
                //configureCellRegion(cell, withLuggageTag: row[rowIndex], connected: true)
                let battery = cell.viewWithTag(1003) as! UILabel
                battery.text = "\(row[rowIndex].minor)%"
                battery.isHidden = (battery.text! == "-1%") ? true : false
                
                // Asynchronously update Database
                DispatchQueue.global().async {
                    self.updateToDatabase(self.row[rowIndex])
                }
            }
        }
    }
    
    func setLuggageImageRange(_ notification: Notification) {
        let key = (notification as NSNotification).userInfo!["key"] as! String
        let rangeImage = (notification as NSNotification).userInfo!["rangeImage"] as! String
        let rowIndex = getObjectIndex(key)
        
        let indexPath = IndexPath(row: rowIndex, section: 0)
        if let cell = tableView.cellForRow(at: indexPath) {
            let customCell = cell as! CustomTableCell
            
            if customCell.customSwitch.on {
                let region = cell.viewWithTag(1002) as! CustomDetectionView
                region.image = UIImage(named: rangeImage)
            }
        }
    }
    
    func transmitActivationKey(_ notification: Notification) {
        guard let key = notification.object as? String else {
            Globals.log("Invalid Activation Key")
            
            return
        }
        
        tktCoreLocation.broadcastActivationKey(activationCode: key)
    }
    
    func longPressGestureRecognized(_ gestureRecognizer: UIGestureRecognizer) {
        let longPress = gestureRecognizer as! UILongPressGestureRecognizer
        let state = longPress.state
        let locationInView = longPress.location(in: tableView)
        let indexPath = tableView.indexPathForRow(at: locationInView)
        
        struct My {
            static var cellSnapshot : UIView? = nil
            static var cellIsAnimating : Bool = false
            static var cellNeedToShow : Bool = false
        }
        struct Path {
            static var initialIndexPath : IndexPath? = nil
        }
        
        switch state {
        case UIGestureRecognizerState.began:
            if indexPath != nil {
                Path.initialIndexPath = indexPath
                let cell = tableView.cellForRow(at: indexPath!) as UITableViewCell!
                My.cellSnapshot  = snapshotOfCell(cell!)
                
                var center = cell?.center
                My.cellSnapshot!.center = center!
                My.cellSnapshot!.alpha = 0.0
                tableView.addSubview(My.cellSnapshot!)
                
                UIView.animate(withDuration: 0.25, animations: { () -> Void in
                    center?.y = locationInView.y
                    My.cellIsAnimating = true
                    My.cellSnapshot!.center = center!
                    My.cellSnapshot!.transform = CGAffineTransform(scaleX: 1.05, y: 1.05)
                    My.cellSnapshot!.alpha = 0.98
                    cell?.alpha = 0.0
                }, completion: { (finished) -> Void in
                    if finished {
                        My.cellIsAnimating = false
                        if My.cellNeedToShow {
                            My.cellNeedToShow = false
                            UIView.animate(withDuration: 0.25, animations: { () -> Void in
                                cell?.alpha = 1
                            })
                        } else {
                            cell?.isHidden = true
                        }
                    }
                })
            }
            
        case UIGestureRecognizerState.changed:
            if My.cellSnapshot != nil {
                var center = My.cellSnapshot!.center
                center.y = locationInView.y
                My.cellSnapshot!.center = center
                
                if ((indexPath != nil) && (indexPath != Path.initialIndexPath)) {
                    let initialPathID = row[(Path.initialIndexPath! as NSIndexPath).row].id
                    row[(Path.initialIndexPath! as NSIndexPath).row].id = row[(indexPath! as NSIndexPath).row].id
                    row[(indexPath! as NSIndexPath).row].id = initialPathID
                    
                    row.insert(row.remove(at: (Path.initialIndexPath! as NSIndexPath).row), at: (indexPath! as NSIndexPath).row)
                    tableView.moveRow(at: Path.initialIndexPath!, to: indexPath!)
                    Path.initialIndexPath = indexPath
                    
                    updateCoreDataModel()
                }
            }
        default:
            if Path.initialIndexPath != nil {
                let cell = tableView.cellForRow(at: Path.initialIndexPath!) as UITableViewCell!
                if My.cellIsAnimating {
                    My.cellNeedToShow = true
                } else {
                    cell?.isHidden = false
                    cell?.alpha = 0.0
                }
                
                UIView.animate(withDuration: 0.25, animations: { () -> Void in
                    My.cellSnapshot!.center = (cell?.center)!
                    My.cellSnapshot!.transform = CGAffineTransform.identity
                    My.cellSnapshot!.alpha = 0.0
                    cell?.alpha = 1.0
                    
                }, completion: { (finished) -> Void in
                    if finished {
                        Path.initialIndexPath = nil
                        My.cellSnapshot!.removeFromSuperview()
                        My.cellSnapshot = nil
                    }
                })
            }
        }
    }
    
    func snapshotOfCell(_ inputView: UIView) -> UIView {
        UIGraphicsBeginImageContextWithOptions(inputView.bounds.size, false, 0.0)
        inputView.layer.render(in: UIGraphicsGetCurrentContext()!)
        let image = UIGraphicsGetImageFromCurrentImageContext()! as UIImage
        UIGraphicsEndImageContext()
        
        let cellSnapshot : UIView = UIImageView(image: image)
        cellSnapshot.layer.masksToBounds = false
        cellSnapshot.layer.cornerRadius = 0.0
        cellSnapshot.layer.shadowOffset = CGSize(width: -5.0, height: 0.0)
        cellSnapshot.layer.shadowRadius = 5.0
        cellSnapshot.layer.shadowOpacity = 0.4
        return cellSnapshot
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == Constants.Segue.AddBeacon {
            let navigationController = segue.destination as! UINavigationController
            let controller = navigationController.topViewController as! BeaconDetailViewController
            controller.delegate = self
            
            controller.beaconReference = row
        } else if segue.identifier == Constants.Segue.EditBeacon {
            let navigationController = segue.destination as! UINavigationController
            let controller = navigationController.topViewController as! BeaconDetailViewController
            controller.delegate = self
            
            if let indexPath = tableView.indexPath(for: sender as! UITableViewCell) {
                controller.beaconToEdit = row[(indexPath as NSIndexPath).row]
                controller.beaconReference = row
            }
        } else if segue.identifier == Constants.Segue.PagerView {
            let navigationController = segue.destination as! UINavigationController
            let controller = navigationController.topViewController as! PagerViewController
            controller.delegate = self
            
            controller.beaconReference = row
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: UITableViewDelegate Methods
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return row.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = self.tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! CustomTableCell
        
        let item = row[(indexPath as NSIndexPath).row]
        cell.delegate = self
        cell.setupWithModel(item)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        let luggage = row[(indexPath as NSIndexPath).row]
        
        let messageString = String(format: NSLocalizedString("delete_luggage", comment: ""), luggage.name)
        
        let actions = [
            UIAlertAction(title: NSLocalizedString("remove", comment: ""), style: .destructive) { (action) in
                
                // TODO
                if luggage.isConnected {
                    if let identifier = self.tktCoreLocation.monitoredRegions[luggage.uuid] {
                        // Stop Monitoring for this Beacon
                        var beaconRegion: CLBeaconRegion?
                        beaconRegion = CLBeaconRegion(proximityUUID: UUID(uuidString: luggage.uuid)!, identifier: identifier)
                        
                        self.tktCoreLocation.stopMonitoringBeacon(beaconRegion, key: luggage.uuid)
                    }
                }
                
                // Delete LocalNotification
                self.deleteLocalNotification(luggage.name, identifier: luggage.uuid)
                
                self.deleteToDatabase(luggage.id)
                
                self.row.remove(at: (indexPath as NSIndexPath).row)
                let indexPaths = [indexPath]
                tableView.deleteRows(at: indexPaths, with: .automatic)
            },
            UIAlertAction(title: NSLocalizedString("cancel", comment: ""), style: .default, handler: nil)
        ]
        
        Globals.showAlert(self, title: NSLocalizedString("delete_luggage_title", comment: ""), message: messageString, animated: true, completion: nil, actions: actions)
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        var height: CGFloat
        var position: CGFloat
        var percent: CGFloat
        
        height =  appLogo.bounds.size.height / 2
        position = max(-scrollView.contentOffset.y, 0.0)
        percent = min(position / height, 1.0)
        
        appLogo.alpha = percent
    }
    
    // MARK: CBCentralManagerDelegate Methods
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch (central.state) {
        case .poweredOn:
            isBluetoothPoweredOn = true
            startMonitoring()
        case .poweredOff:
            isBluetoothPoweredOn = false
            checkLuggageTagRegion()
        default:
            break
        }
    }
    
    // MARK: TKTCoreLocationDelegate Methods
    func onBackgroundLocationAccessDisabled(_ accessCode: Int32) {
        if (accessCode == 0) {
            tktCoreLocation.locationManager.requestAlwaysAuthorization()
        } else {
            let actions = [
                UIAlertAction(title: NSLocalizedString("settings", comment: ""), style: .default) { (action) in
                    if let url = URL(string:UIApplicationOpenSettingsURLString) {
                        UIApplication.shared.openURL(url)
                    }
                },
                UIAlertAction(title: NSLocalizedString("cancel", comment: ""), style: .cancel, handler: nil)
            ]
            
            Globals.showAlert(self, title: NSLocalizedString("location_access_disabled", comment: ""), message: NSLocalizedString("location_access_disabled_settings", comment: ""), animated: true, completion: nil, actions: actions)
            
            NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.Notification.OnBackgroundAccessDisabled), object: nil, userInfo: nil)
        }
    }
    
    func didStartMonitoring() {
        isMonitoring = true
    }
    
    
    func didStopMonitoring() {
        isMonitoring = false
    }
    
    func monitoringDidFail() {}
    
    func didEnterRegion(_ region: CLBeaconRegion) {
        
        for beacon in row {
            if (beacon.uuid == region.proximityUUID.uuidString) {
                if (beacon.regionState != Constants.Proximity.Inside) {
                    
                    if let index = row.index(of: beacon) {
                        let indexPath = IndexPath(row: index, section: 0)
                        row[(indexPath as NSIndexPath).row].regionState = Constants.Proximity.Inside
                        NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.Proximity.Inside), object: nil, userInfo: ["region": region])
                        createLocalNotification(beacon.name, identifier: beacon.uuid, message: NSLocalizedString("has_arrived", comment: ""))
                        
                        if let cell = tableView.cellForRow(at: indexPath) {
                            let cellSwitch = cell.viewWithTag(1004) as! SevenSwitch
                            if (!cellSwitch.isOn()) {
                                cellSwitch.setOn(true, animated: false)
                            }
                            configureCellRegion(cell, withLuggageTag: beacon, connected: true)
                        }
                        
                        if (!row[(indexPath as NSIndexPath).row].activated) {
                            row[(indexPath as NSIndexPath).row].activated = true
                            updateToDatabase(row[(indexPath as NSIndexPath).row])
                        }
                    }
                }
            }
        }
        
    }
    
    func didExitRegion(_ region: CLBeaconRegion) {  ///not updating ui od switch here
        
        for beacon in row {
            if (beacon.uuid == region.proximityUUID.uuidString) {
                if (beacon.regionState != Constants.Proximity.Outside) {
                    if let index = row.index(of: beacon) {
                        let indexPath = IndexPath(row: index, section: 0)
                        row[(indexPath as NSIndexPath).row].regionState = Constants.Proximity.Outside
                        NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.Proximity.Outside), object: nil, userInfo: ["region": region])
                        createLocalNotification(beacon.name, identifier: beacon.uuid, message: NSLocalizedString("is_gone", comment: ""))
                        
                        if let cell = tableView.cellForRow(at: indexPath) {
                            configureCellRegion(cell, withLuggageTag: beacon, connected: false)
                        }
                    }
                }
            }
        }
        
    }
    
    func didRangeBeacon(_ manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], inRegion region: CLBeaconRegion) {}
    
    // MARK: BeaconDetailViewControllerDelegate Methods
    func beaconDetailViewController(_ controller: BeaconDetailViewController, didFinishAddingItem item: LuggageTag) {
        let index = getMaxID() + 1
        let count = row.count
        
        row.append(item)
        item.id = index
        
        let indexPath = IndexPath(row: count, section: 0)
        let indexPaths = [indexPath]
        
        tableView.beginUpdates()
        tableView.insertRows(at: indexPaths, with: .automatic)
        tableView.endUpdates()
        
        if let cell = tableView.cellForRow(at: indexPath) {
            let battery = cell.viewWithTag(1003) as! UILabel
            battery.text = "\(item.minor)%"
            battery.isHidden = (battery.text! == "-1%") ? true : false
        }
        
        // Save item in Database
        saveToDatabase(item)
        
        dismiss(animated: true, completion: nil)
    }
    
    
    func SavingNewLugguageItem(_ itemm: Notification){
        
        let index = getMaxID() + 1
        let count = row.count
        let item = itemm.object as! LuggageTag
        row.append(item)
        item.id = index
        
        let indexPath = IndexPath(row: count, section: 0)
        let indexPaths = [indexPath]
        
        tableView.beginUpdates()
        tableView.insertRows(at: indexPaths, with: .automatic)
        tableView.endUpdates()
        
        if let cell = tableView.cellForRow(at: indexPath) {
            let battery = cell.viewWithTag(1003) as! UILabel
            battery.text = "\(item.minor)%"
            battery.isHidden = (battery.text! == "-1%") ? true : false
        }
        
        // Save item in Database
        saveToDatabase(item)
        
        dismiss(animated: true, completion: nil)
        
    }
    
    func beaconDetailViewController(_ controller: BeaconDetailViewController, didFinishEditingItem item: LuggageTag) {
        if let index = row.index(of: item) {
            let indexPath = IndexPath(row: index, section: 0)
            if let cell = tableView.cellForRow(at: indexPath) {
                configureCell(cell, withLuggageTag: item)
                
                if (item.regionState == Constants.Proximity.Inside) {
                    configureCellRegion(cell, withLuggageTag: item, connected: true)
                } else {
                    configureCellRegion(cell, withLuggageTag: item, connected: false)
                }
            }
            
            updateToDatabase(item)
        }
        
        dismiss(animated: true, completion: nil)
    }
    
    func stopMonitoring(didStopMonitoring item: LuggageTag) {  ///STOP SCAN
        var beaconRegion: CLBeaconRegion?
        beaconRegion = CLBeaconRegion(proximityUUID: UUID(uuidString: item.uuid)!, identifier: item.uuid)
        
        tktCoreLocation.stopMonitoringBeacon(beaconRegion, key: item.uuid)
    }
    
    func didBluetoothPoweredOff(didPowerOff item: LuggageTag) {  //// NOT USED
        if let index = row.index(of: item) {
            let indexPath = IndexPath(row: index, section: 0)
            if let cell = tableView.cellForRow(at: indexPath) {
                configureCellRegion(cell, withLuggageTag: item, connected: false)
            }
        }
    }
    
    func connectActivatingBeacon(item: LuggageTag) {
        // If there is a existing connnection in this UUID, disconnect it first
        
        //commented ny EDMER MArch 24, this block is to check if device has been activated before
        
        //        if let identifier = tktCoreLocation.monitoredRegions[item.uuid] {
        //            //Globals.log("STOP THE FIRST BEACON WHO CONNECTED FIRST THEN MONITORED AGAIN WITH A NEW ONE")
        //            // Stop Monitoring for this Beacon
        //            var beaconRegion: CLBeaconRegion?
        //            beaconRegion = CLBeaconRegion(proximityUUID: UUID(uuidString: item.uuid)!, identifier: identifier)
        //            Globals.log("BEACON REGION Called")
        //            // Stop Monitoring this Specific Beacon.
        //            tktCoreLocation.stopMonitoringBeacon(beaconRegion, key: item.uuid)
        //        }
        Globals.log("connectActivatingBeacon HERE")
        startMonitoringforBeacon(item)
    }
    
    func disconnectActivatingBeacon(item: LuggageTag) {  ///DISCONNECT IF ACTIVATION IS NOT SUCCESSFULL, DELEGATE OF BEACONVIEWCONTROLLER
        stopMonitoring(didStopMonitoring: item)
    }
    
    func didFinishActivatingBeacon(_ controller: BeaconDetailViewController, item: LuggageTag, isFromEdit: Bool) {///CHECK THIS FUNC, CREATE NEW BEACON, INSERT TO TABLE
        if (isFromEdit) {
            // From Edit
            if let index = row.index(of: item) {
                let indexPath = IndexPath(row: index, section: 0)
                if let cell = tableView.cellForRow(at: indexPath) {
                    configureCell(cell, withLuggageTag: item)
                    Globals.log("didFinishActivatingBeacon 1 item.isConnected \(item.isConnected)")
                    configureCellRegion(cell, withLuggageTag: item, connected: item.isConnected)
                    
                    let customSwitch = cell.viewWithTag(1004) as! SevenSwitch
                    Globals.log("didFinishActivatingBeacon 2 item.isConnected \(item.isConnected)")
                    customSwitch.setOn(item.isConnected, animated: false)
                }
                
                updateToDatabase(item)
            }
            
            dismiss(animated: true, completion: nil)
        } else {
            // New Beacon
            let index = getMaxID() + 1
            let count = row.count
            
            row.append(item)
            item.id = index
            
            let indexPath = IndexPath(row: count, section: 0)
            let indexPaths = [indexPath]
            
            tableView.beginUpdates()
            tableView.insertRows(at: indexPaths, with: .automatic)
            tableView.endUpdates()
            
            if let cell = tableView.cellForRow(at: indexPath) {
                let battery = cell.viewWithTag(1003) as! UILabel
                battery.text = "\(item.minor)%"
                battery.isHidden = (battery.text! == "-1%") ? true : false
            }
            
            // Save item in Database
            saveToDatabase(item)
            
            dismiss(animated: true, completion: nil)
        }
    }
    
    // MARK: CustomTableCellDelegate
    func didTappedSwitchCell(_ cell: CustomTableCell) {
        let indexPath = tableView.indexPath(for: cell)
        let item = row[((indexPath as NSIndexPath?)?.row)!]
        item.isConnected = cell.customSwitch.on
        row[((indexPath as NSIndexPath?)?.row)!].regionState = Constants.Proximity.Outside
        
        if cell.customSwitch.on {
            if (!isBluetoothPoweredOn) {
                showAlertForSettings()
                
            }else{
                // Start Monitoring for this Beacon
                var beaconRegion: CLBeaconRegion?
                beaconRegion = CLBeaconRegion(proximityUUID: UUID(uuidString: item.uuid)!, identifier: item.uuid)
                // later, these values can be set from the UI
                beaconRegion!.notifyEntryStateOnDisplay = true
                beaconRegion!.notifyOnEntry = true
                beaconRegion!.notifyOnExit = true
                
                tktCoreLocation.startMonitoring(beaconRegion)
            }
            
        } else {    ///WHEN OFF
            if let identifier = tktCoreLocation.monitoredRegions[item.uuid] {
                // Delete LocalNotification
                deleteLocalNotification(row[((indexPath as NSIndexPath?)?.row)!].name, identifier: row[((indexPath as NSIndexPath?)?.row)!].uuid)
                
                row[((indexPath as NSIndexPath?)?.row)!].regionState = Constants.Proximity.Outside
                configureCellRegion(cell, withLuggageTag: item, connected: false)
                 
                // Stop Monitoring for this Beacon
                var beaconRegion: CLBeaconRegion?
                beaconRegion = CLBeaconRegion(proximityUUID: UUID(uuidString: item.uuid)!, identifier: identifier)
                
                // Stop Monitoring this Specific Beacon.
                tktCoreLocation.stopMonitoringBeacon(beaconRegion, key: item.uuid)
            }
        }
        
        updateToDatabase(item)
    }
    
    // MARK: Private Methods
    fileprivate func showAlertForSettings() {
        let actions = [
            UIAlertAction(title: NSLocalizedString("settings", comment: ""), style: .default) { (action) in
                if let url = URL(string:"prefs:root=Bluetooth") {
                    UIApplication.shared.openURL(url)
                }
            },
            UIAlertAction(title: NSLocalizedString("ok", comment: ""), style: .cancel, handler: nil)
        ]
        
        Globals.showAlert(self, title: NSLocalizedString("app_name", comment: ""), message: NSLocalizedString("turn_on_bluetooth", comment: ""), animated: true, completion: nil, actions: actions)
    }
    
    fileprivate func configureCell(_ cell: UITableViewCell, withLuggageTag item: LuggageTag) {///UPDSTE LABEL AND CUSTOM BUTTON
        let label = cell.viewWithTag(1000) as! UILabel
        let photo = cell.viewWithTag(1001) as! CustomButton
        
        if (item.photo != nil) {
            photo.setImage(UIImage(data: item.photo! as Data)!, for: UIControlState())
            photo.imageView?.contentMode = UIViewContentMode.center
        }
        
        label.text = item.name
    }
    
    fileprivate func configureCellRegion(_ cell: UITableViewCell, withLuggageTag item: LuggageTag, connected: Bool) {
        let region = cell.viewWithTag(1002) as! CustomDetectionView
        let battery = cell.viewWithTag(1003) as! UILabel
        battery.text = "\(item.minor)%"
        
        if (connected) {
            region.image = UIImage(named: "range_close")
            battery.isHidden = (battery.text! == "-1%") ? true : false
        } else {
            region.image = UIImage(named: "range_no_detection")
            battery.isHidden = true
        }
    }
    
    fileprivate func loadBeaconItems() {
        // Loop Through All BeaconItem and put it in Model
        for beacon in frc.fetchedObjects! {
            let item = LuggageTag()
            let index: Int = Int(beacon.id!)
            let i: Int = Int(beacon.connection!)
            var isConnected = false
            if (i == 1) {
                isConnected = true
            }
            
            let x: Int = Int(beacon.activated!)
            var isActivated = false
            if (x == 1) {
                isActivated = true
            }
            
            item.id = index
            
            if beacon.photo != nil {
                item.photo = beacon.photo! as Data
            }
            
            item.name = beacon.name!
            item.uuid = beacon.uuid!
            item.major = beacon.major!
            item.minor = beacon.minor!
            item.regionState = Constants.Proximity.Unknown
            item.isConnected = isConnected
            item.activation_code = beacon.activation_code!
            item.activation_key = beacon.activation_key!
            item.activated = isActivated
            
            row.append(item)
        }
        
        // Reload TableView
        self.tableView.reloadData()
    }
    
    fileprivate func startMonitoring() {//called WHEN BLUETOTH ON/OF
        
        if row.count > 0 {
            for beacon in row {
                if beacon.isConnected {
                    var beaconRegion: CLBeaconRegion?
                    beaconRegion = CLBeaconRegion(proximityUUID: UUID(uuidString: beacon.uuid)!, identifier: beacon.uuid)
                    // Stop Beacon First
                    tktCoreLocation.stopMonitoringBeacon(beaconRegion, key: "")
                    
                    // later, these values can be set from the UI
                    beaconRegion!.notifyEntryStateOnDisplay = true
                    beaconRegion!.notifyOnEntry = true
                    beaconRegion!.notifyOnExit = true
                    
                    tktCoreLocation.startMonitoring(beaconRegion)
                } else {
                    Globals.log("\(beacon.name) is disabled")
                }
            }
        } else {
            Globals.log("No Beacon Available")
        }
    }
    
    fileprivate func startMonitoringforBeacon(_ beaconItem: LuggageTag) {/////   CALLED SWITCH ON/OFF
        
        var beaconRegion: CLBeaconRegion?
        beaconRegion = CLBeaconRegion(proximityUUID: UUID(uuidString: beaconItem.uuid)!, identifier: beaconItem.uuid)
        // later, these values can be set from the UI
        beaconRegion!.notifyEntryStateOnDisplay = true
        beaconRegion!.notifyOnEntry = true
        beaconRegion!.notifyOnExit = true
        Globals.log("LISTVIEW startMonitoringforBeacon")
        tktCoreLocation.startMonitoring(beaconRegion)
        
    }
    
    fileprivate func checkLuggageTagRegion() {  /// FOR BLUTOOTH, THIS FUNCTION TURNS OFF SCANNING OR MAKE GREEN RSSI TO GRAY
        
        if row.count > 0 {
            for beacon in row {
                if (beacon.regionState == Constants.Proximity.Inside) {
                    // Stop Monitoring for this Beacon
                    var beaconRegion: CLBeaconRegion?
                    beaconRegion = CLBeaconRegion(proximityUUID: UUID(uuidString: beacon.uuid)!, identifier: beacon.uuid)
                    
                    // Stop Monitoring this Specific Beacon.
                    tktCoreLocation.stopMonitoringBeacon(beaconRegion, key: "")
                    
                    if let index = row.index(of: beacon) {
                        let indexPath = IndexPath(row: index, section: 0)
                        row[(indexPath as NSIndexPath).row].regionState = Constants.Proximity.Outside
                        
                        if let cell = tableView.cellForRow(at: indexPath) {
                            configureCellRegion(cell, withLuggageTag: beacon, connected: false)
                        }
                    }
                }
            }
        }
    }
    
    fileprivate func getMaxID() -> Int {
        
        if row.count > 0 {
            var ids = [Int]()
            
            for luggage in row {
                ids.append(luggage.id)
            }
            
            return ids.max()!
        }
        
        return 0
    }
    
    fileprivate func saveToDatabase(_ beaconItem: LuggageTag) {
        let entityDescription = NSEntityDescription.entity(forEntityName: "BeaconItem", in: moc)
        
        let item = BeaconItem(entity: entityDescription!, insertInto: moc)
        let id = NSNumber(value: beaconItem.id as Int)
        
        item.id = id
        item.photo = beaconItem.photo as NSData?
        item.name = beaconItem.name
        item.uuid = beaconItem.uuid
        item.major = beaconItem.major
        item.minor = beaconItem.minor
        Globals.log("saveToDatabase item.isConnected \(beaconItem.isConnected)")
        item.connection = beaconItem.isConnected as NSNumber?
        item.activation_code = beaconItem.activation_code
        item.activation_key = beaconItem.activation_key
        item.activated = beaconItem.activated as NSNumber?
        
        do {
            try moc.save()
            Globals.log("Saved Successfuly to Database")
        } catch let error as NSError{
            fatalError("Failed to saving to Database : \(error)")
        }
    }
    
    fileprivate func updateToDatabase(_ item: LuggageTag) {
        let entityDescription = NSEntityDescription.entity(forEntityName: "BeaconItem", in: moc)
        
        let req: NSFetchRequest<BeaconItem> = NSFetchRequest()
        req.entity = entityDescription
        let index = "\(item.id)"
        
        let condition = NSPredicate(format: "id == \(index)")
        
        req.predicate = condition
        
        do {
            let result = try moc.fetch(req)
            
            if result.count > 0 {
                let beacon = result[0]
                beacon.setValue(item.photo, forKey: "photo")
                beacon.setValue(item.name, forKey: "name")
                beacon.setValue(item.uuid, forKey: "uuid")
                beacon.setValue(item.major, forKey: "major")
                beacon.setValue(item.minor, forKey: "minor")
                Globals.log("updateToDatabase item.isConnected \(item.isConnected)")
                beacon.setValue(item.isConnected, forKey: "connection")
                beacon.setValue(item.activation_code, forKey: "activation_code")
                beacon.setValue(item.activation_key, forKey: "activation_key")
                beacon.setValue(item.activated, forKey: "activated")
                do {
                    try moc.save()
                    Globals.log("Successfully Updated Database")
                } catch let error as NSError{
                    fatalError("Failed to updating to Database : \(error)")
                }
            } else {
                Globals.log("No Record Found")
            }
        } catch let error as NSError {
            fatalError("Error: \(error)")
        }
        
    }
    
    fileprivate func deleteToDatabase(_ id: Int) {
        let entityDescription = NSEntityDescription.entity(forEntityName: "BeaconItem", in: moc)
        
        let req: NSFetchRequest<BeaconItem> = NSFetchRequest()
        req.entity = entityDescription
        let index = "\(id)"
        
        let condition = NSPredicate(format: "id == \(index)")
        
        req.predicate = condition
        
        do {
            let result: [BeaconItem]? = try moc.fetch(req)
            
            if let res = result {
                if res.count > 0 {
                    moc.delete(res[0])
                    do {
                        try moc.save()
                        Globals.log("Successfully Deleted Item")
                    } catch let error as NSError{
                        fatalError("Failed to Delete Item : \(error)")
                    }
                }
            }
        } catch let error as NSError {
            fatalError("Error: \(error)")
        }
    }
    
    fileprivate func updateCoreDataModel() {  ///UPDATE WHEN DOING GESTURE,MOVE ROW FROM TABLEVIEW
        do {
            // Refetch FRC to make sure it is the new CoreData
            try frc.performFetch()
            
            for luggage in row {
                for beacon in frc.fetchedObjects! {
                    if (luggage.uuid == beacon.uuid!) {
                        if (luggage.id != beacon.id! as Int) {
                            beacon.id = luggage.id as NSNumber
                        }
                    }
                }
            }
            
            do {
                try moc.save()
                Globals.log("Succesfuly Update CoreData")
            } catch let error as NSError{
                fatalError("Failed to Update CoreData : \(error)")
            }
            
        } catch {
            Globals.log("Failed to perform update CoreDataModel fetch.")
        }
        
    }
    
    fileprivate func createLocalNotification(_ name: String, identifier: String, message: String) {
        let localNotification = UILocalNotification()
        
        localNotification.fireDate = Date(timeIntervalSinceNow: 1)
        //localNotification.applicationIconBadgeNumber = 1
        localNotification.soundName = UILocalNotificationDefaultSoundName
        
        localNotification.userInfo = ["name" : name, "identifier": identifier]
        localNotification.alertBody = "Your Bag \(name) \(message)"
        Globals.log("name \(name)")
        Globals.log("identifier \(identifier)")
        Globals.log("message \(message)")
        UIApplication.shared.scheduleLocalNotification(localNotification)
    }
    
    fileprivate func deleteLocalNotification(_ name: String, identifier: String) {
        let scheduledNotifications: NSArray = UIApplication.shared.scheduledLocalNotifications! as NSArray
        
        if(scheduledNotifications.count > 0) {
            for  notification in scheduledNotifications {
                let n = notification as! UILocalNotification
                let notifName = n.userInfo!["name"] as! String
                let notifIdentifier = n.userInfo!["identifier"] as! String
                
                if (name == notifName && identifier == notifIdentifier) {
                    UIApplication.shared.cancelLocalNotification(n)
                }
            }
        }
    }
    
    fileprivate func formatNavigationBar() {
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.isTranslucent = true
        
    }
    
    fileprivate func applicationInfo() {/// SET VERSION NUMBER AT THE BOTTOM
        appInfoView.alpha = 0.6
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            versionLabel.text = "v\(version)"
        }
        
        let date = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy"
        let company_label = NSLocalizedString("tektos_limited", comment: "")
        let year = formatter.string(from: date)
        
        companyLabel.text = "\(company_label)\(year)"
        rightsLabel.text = NSLocalizedString("alrights_reserved", comment: "")
    }
    
    fileprivate func getObjectIndex(_ id: String) -> Int {
        for (index, element) in row.enumerated() {
            if(id == element.uuid) {
                return index
            }
        }
        
        return 0
    }
    
    
    func didShowBluetoothState(_ notification: Notification) {
        let alertController = UIAlertController(title: "Turn On Bluetooth", message: "Turn On Bluetooth to Allow Bag iTag to Connect", preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "Settings", style: .cancel) { (action) in
            let url = NSURL(string: UIApplicationOpenSettingsURLString)
            UIApplication.shared.openURL(url! as URL)
        }
        alertController.addAction(cancelAction)
        let okAction = UIAlertAction(title: "OK", style: .default) { (action) in
            // do nothing
            
        }
        alertController.addAction(okAction)
        present(alertController, animated: true, completion: nil)
    }
    
    deinit {
        //        NotificationCenter.default.removeObserver(self)
    }
    
    
}



