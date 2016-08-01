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
  static var sourceIndexPath: NSIndexPath!
}

class ListViewController: UIViewController, CBCentralManagerDelegate, TKTCoreLocationDelegate, UITableViewDataSource,
UITableViewDelegate, BeaconDetailViewControllerDelegate, NSFetchedResultsControllerDelegate, CustomTableCellDelegate  {
  
  var row: [LuggageTag]
  
  let moc = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext
  
  var frc: NSFetchedResultsController = NSFetchedResultsController()
  
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
  func fetchRequest() -> NSFetchRequest {
    let fetchRequest = NSFetchRequest(entityName: "BeaconItem")
    let sortDescriptor = NSSortDescriptor(key: "id", ascending: true)
    fetchRequest.sortDescriptors = [sortDescriptor]
    
    return fetchRequest
  }
  
  func getFRC() -> NSFetchedResultsController {
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
  }
  
  func longPressGestureRecognized(gestureRecognizer: UIGestureRecognizer) {
    let longPress = gestureRecognizer as! UILongPressGestureRecognizer
    let state = longPress.state
    let locationInView = longPress.locationInView(tableView)
    let indexPath = tableView.indexPathForRowAtPoint(locationInView)
    
    struct My {
      static var cellSnapshot : UIView? = nil
      static var cellIsAnimating : Bool = false
      static var cellNeedToShow : Bool = false
    }
    struct Path {
      static var initialIndexPath : NSIndexPath? = nil
    }
    
    switch state {
    case UIGestureRecognizerState.Began:
      if indexPath != nil {
        Path.initialIndexPath = indexPath
        let cell = tableView.cellForRowAtIndexPath(indexPath!) as UITableViewCell!
        My.cellSnapshot  = snapshotOfCell(cell)
        
        var center = cell.center
        My.cellSnapshot!.center = center
        My.cellSnapshot!.alpha = 0.0
        tableView.addSubview(My.cellSnapshot!)
        
        UIView.animateWithDuration(0.25, animations: { () -> Void in
          center.y = locationInView.y
          My.cellIsAnimating = true
          My.cellSnapshot!.center = center
          My.cellSnapshot!.transform = CGAffineTransformMakeScale(1.05, 1.05)
          My.cellSnapshot!.alpha = 0.98
          cell.alpha = 0.0
          }, completion: { (finished) -> Void in
            if finished {
              My.cellIsAnimating = false
              if My.cellNeedToShow {
                My.cellNeedToShow = false
                UIView.animateWithDuration(0.25, animations: { () -> Void in
                  cell.alpha = 1
                })
              } else {
                cell.hidden = true
              }
            }
        })
      }
      
    case UIGestureRecognizerState.Changed:
      if My.cellSnapshot != nil {
        var center = My.cellSnapshot!.center
        center.y = locationInView.y
        My.cellSnapshot!.center = center
        
        if ((indexPath != nil) && (indexPath != Path.initialIndexPath)) {
          let initialPathID = row[Path.initialIndexPath!.row].id
          row[Path.initialIndexPath!.row].id = row[indexPath!.row].id
          row[indexPath!.row].id = initialPathID
          
          row.insert(row.removeAtIndex(Path.initialIndexPath!.row), atIndex: indexPath!.row)
          tableView.moveRowAtIndexPath(Path.initialIndexPath!, toIndexPath: indexPath!)
          Path.initialIndexPath = indexPath
          
          updateCoreDataModel()
        }
      }
    default:
      if Path.initialIndexPath != nil {
        let cell = tableView.cellForRowAtIndexPath(Path.initialIndexPath!) as UITableViewCell!
        if My.cellIsAnimating {
          My.cellNeedToShow = true
        } else {
          cell.hidden = false
          cell.alpha = 0.0
        }
        
        UIView.animateWithDuration(0.25, animations: { () -> Void in
          My.cellSnapshot!.center = cell.center
          My.cellSnapshot!.transform = CGAffineTransformIdentity
          My.cellSnapshot!.alpha = 0.0
          cell.alpha = 1.0
          
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
  
  func snapshotOfCell(inputView: UIView) -> UIView {
    UIGraphicsBeginImageContextWithOptions(inputView.bounds.size, false, 0.0)
    inputView.layer.renderInContext(UIGraphicsGetCurrentContext()!)
    let image = UIGraphicsGetImageFromCurrentImageContext() as UIImage
    UIGraphicsEndImageContext()
    
    let cellSnapshot : UIView = UIImageView(image: image)
    cellSnapshot.layer.masksToBounds = false
    cellSnapshot.layer.cornerRadius = 0.0
    cellSnapshot.layer.shadowOffset = CGSizeMake(-5.0, 0.0)
    cellSnapshot.layer.shadowRadius = 5.0
    cellSnapshot.layer.shadowOpacity = 0.4
    return cellSnapshot
  }
  
  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    if segue.identifier == Constants.Segue.AddBeacon {
      let navigationController = segue.destinationViewController as! UINavigationController
      let controller = navigationController.topViewController as! BeaconDetailViewController
      controller.delegate = self
      
      controller.beaconReference = row
    } else if segue.identifier == Constants.Segue.EditBeacon {
      let navigationController = segue.destinationViewController as! UINavigationController
      let controller = navigationController.topViewController as! BeaconDetailViewController
      controller.delegate = self
      
      if let indexPath = tableView.indexPathForCell(sender as! UITableViewCell) {
        controller.beaconToEdit = row[indexPath.row]
        
        controller.beaconReference = row
      }
    }
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
  
  // MARK: UITableViewDelegate Methods
  func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return row.count
  }
  
  func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    let cell = self.tableView.dequeueReusableCellWithIdentifier("cell", forIndexPath: indexPath) as! CustomTableCell
    
    let item = row[indexPath.row]
    cell.delegate = self
    cell.setupWithModel(item)
    
    return cell
  }
  
  func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
    let luggage = row[indexPath.row]
    
    let messageString = String(format: NSLocalizedString("delete_luggage", comment: ""), luggage.name)
    
    let actions = [
      UIAlertAction(title: NSLocalizedString("remove", comment: ""), style: .Destructive) { (action) in
        
        if luggage.isConnected {
          // Stop Monitoring for this Beacon
          var beaconRegion: CLBeaconRegion?
          beaconRegion = CLBeaconRegion(proximityUUID: NSUUID(UUIDString: luggage.uuid)!, identifier: luggage.name)
          
          self.tktCoreLocation.stopMonitoringBeacon(beaconRegion, removeObject: true)
        }
        
        // Delete LocalNotification
        self.deleteLocalNotification(luggage.name, identifier: luggage.uuid)
        
        self.deleteToDatabase(luggage.id)
        
        self.row.removeAtIndex(indexPath.row)
        let indexPaths = [indexPath]
        tableView.deleteRowsAtIndexPaths(indexPaths, withRowAnimation: .Automatic)
      },
      UIAlertAction(title: NSLocalizedString("cancel", comment: ""), style: .Default, handler: nil)
    ]
    
    Globals.showAlert(self, title: NSLocalizedString("delete_luggage_title", comment: ""), message: messageString, animated: true, completion: nil, actions: actions)
  }
  
  func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
    tableView.deselectRowAtIndexPath(indexPath, animated: true)
  }
  
  func scrollViewDidScroll(scrollView: UIScrollView) {
    var height: CGFloat
    var position: CGFloat
    var percent: CGFloat
    
    height =  appLogo.bounds.size.height / 2
    position = max(-scrollView.contentOffset.y, 0.0)
    percent = min(position / height, 1.0)
    
    appLogo.alpha = percent
  }

  // MARK: CBCentralManagerDelegate Methods
  func centralManagerDidUpdateState(central: CBCentralManager) {
    switch (central.state) {
    case .PoweredOn:
      isBluetoothPoweredOn = true
      startMonitoring()
    case .PoweredOff:
      isBluetoothPoweredOn = false
      checkLuggageTagRegion()
    default:
      break
    }
  }
  
  // MARK: TKTCoreLocationDelegate Methods
  func onBackgroundLocationAccessDisabled() {
    let actions = [
      UIAlertAction(title: NSLocalizedString("settings", comment: ""), style: .Default) { (action) in
        if let url = NSURL(string:UIApplicationOpenSettingsURLString) {
          UIApplication.sharedApplication().openURL(url)
        }
      },
      UIAlertAction(title: NSLocalizedString("cancel", comment: ""), style: .Cancel, handler: nil)
    ]
    
    Globals.showAlert(self, title: NSLocalizedString("location_access_disabled", comment: ""), message: NSLocalizedString("location_access_disabled_settings", comment: ""), animated: true, completion: nil, actions: actions)
  }
  
  func didStartMonitoring() {
    isMonitoring = true
  }
  
  
  func didStopMonitoring() {
    isMonitoring = false
  }
  
  func monitoringDidFail() {}
  
  func didEnterRegion(region: CLBeaconRegion) {
    for beacon in row {
      if (beacon.name == region.identifier && beacon.uuid == region.proximityUUID.UUIDString) {
        if (beacon.regionState != Constants.Proximity.Inside) {
          if let index = row.indexOf(beacon) {
            let indexPath = NSIndexPath(forRow: index, inSection: 0)
            row[indexPath.row].regionState = Constants.Proximity.Inside
            if let cell = tableView.cellForRowAtIndexPath(indexPath) {
              configureCellRegion(cell, withLuggageTag: beacon, connected: true)
              createLocalNotification(region.identifier, identifier: beacon.uuid, message: NSLocalizedString("has_arrived", comment: ""))
            }
          }
        }
      }
    }
  }
  
  func didExitRegion(region: CLBeaconRegion) {
    for beacon in row {
      if (beacon.name == region.identifier) {
        if (beacon.regionState != Constants.Proximity.Outside) {
          if let index = row.indexOf(beacon) {
            let indexPath = NSIndexPath(forRow: index, inSection: 0)
            row[indexPath.row].regionState = Constants.Proximity.Outside
            if let cell = tableView.cellForRowAtIndexPath(indexPath) {
              configureCellRegion(cell, withLuggageTag: beacon, connected: false)
              createLocalNotification(region.identifier, identifier: beacon.uuid, message: NSLocalizedString("is_gone", comment: ""))
            }
          }
          
        }
      }
    }
  }
  
  func didRangeBeacon(manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], inRegion region: CLBeaconRegion) {}
  
  // MARK: BeaconDetailViewControllerDelegate Methods
  func beaconDetailViewController(controller: BeaconDetailViewController, didFinishAddingItem item: LuggageTag) {
    let index = getMaxID() + 1
    let count = row.count
    
    row.append(item)
    item.id = index
    
    let indexPath = NSIndexPath(forRow: count, inSection: 0)
    let indexPaths = [indexPath]
    
    tableView.beginUpdates()
    tableView.insertRowsAtIndexPaths(indexPaths, withRowAnimation: .Automatic)
    tableView.endUpdates()
    
    // Save item in Database
    saveToDatabase(item)

    dismissViewControllerAnimated(true, completion: nil)
  }
  
  func beaconDetailViewController(controller: BeaconDetailViewController, didFinishEditingItem item: LuggageTag) {
    if let index = row.indexOf(item) {
      let indexPath = NSIndexPath(forRow: index, inSection: 0)
      if let cell = tableView.cellForRowAtIndexPath(indexPath) {
        configureCell(cell, withLuggageTag: item)
        configureCellRegion(cell, withLuggageTag: item, connected: false)
      }
      
      if (item.isConnected) {
        startMonitoringforBeacon(item)
      }
      
      updateToDatabase(item)
    }
  
    dismissViewControllerAnimated(true, completion: nil)
  }
  
  func stopMonitoring(didStopMonitoring item: LuggageTag) {
    var beaconRegion: CLBeaconRegion?
    beaconRegion = CLBeaconRegion(proximityUUID: NSUUID(UUIDString: item.uuid)!, identifier: item.name)
    tktCoreLocation.stopMonitoringBeacon(beaconRegion, removeObject: true)
  }
  
  func didBluetoothPoweredOff(didPowerOff item: LuggageTag) {
    if let index = row.indexOf(item) {
      let indexPath = NSIndexPath(forRow: index, inSection: 0)
      if let cell = tableView.cellForRowAtIndexPath(indexPath) {
        configureCellRegion(cell, withLuggageTag: item, connected: false)
      }
    }
  }
  
  // MARK: CustomTableCellDelegate
  func didTappedSwitchCell(cell: CustomTableCell) {
    let indexPath = tableView.indexPathForCell(cell)
    let item = row[(indexPath?.row)!]
    item.isConnected = cell.customSwitch.on
    
    row[(indexPath?.row)!].regionState = Constants.Proximity.Outside
    
    if cell.customSwitch.on {
      if (!isBluetoothPoweredOn) {
        showAlertForSettings()
      }
      
      // Start Monitoring for this Beacon
      var beaconRegion: CLBeaconRegion?
      beaconRegion = CLBeaconRegion(proximityUUID: NSUUID(UUIDString: item.uuid)!, identifier: item.name)
      // later, these values can be set from the UI
      beaconRegion!.notifyEntryStateOnDisplay = true
      beaconRegion!.notifyOnEntry = true
      beaconRegion!.notifyOnExit = true
      
      tktCoreLocation.startMonitoring(beaconRegion)
    } else {
      // Delete LocalNotification
      deleteLocalNotification(row[(indexPath?.row)!].name, identifier: row[(indexPath?.row)!].uuid)
      
      row[(indexPath?.row)!].regionState = Constants.Proximity.Outside
      configureCellRegion(cell, withLuggageTag: item, connected: false)
      
      // Stop Monitoring for this Beacon
      var beaconRegion: CLBeaconRegion?
      beaconRegion = CLBeaconRegion(proximityUUID: NSUUID(UUIDString: item.uuid)!, identifier: item.name)
      
      // Stop Monitoring this Specific Beacon.
      tktCoreLocation.stopMonitoringBeacon(beaconRegion, removeObject: true)
    }
    
    updateToDatabase(item)
  }
  
  // MARK: Private Methods
  private func showAlertForSettings() {
    let actions = [
      UIAlertAction(title: NSLocalizedString("settings", comment: ""), style: .Default) { (action) in
        if let url = NSURL(string:UIApplicationOpenSettingsURLString) {
          UIApplication.sharedApplication().openURL(url)
        }
      },
      UIAlertAction(title: NSLocalizedString("ok", comment: ""), style: .Cancel, handler: nil)
    ]
    
    Globals.showAlert(self, title: NSLocalizedString("app_name", comment: ""), message: NSLocalizedString("turn_on_bluetooth", comment: ""), animated: true, completion: nil, actions: actions)
  }
  
  private func configureCell(cell: UITableViewCell, withLuggageTag item: LuggageTag) {
    let label = cell.viewWithTag(1000) as! UILabel
    let photo = cell.viewWithTag(1001) as! CustomButton
    
    if (item.photo != nil) {
      photo.setImage(UIImage(data: item.photo!)!, forState: .Normal)
      photo.imageView?.contentMode = UIViewContentMode.Center
    }
    
    label.text = item.name
  }
  
  private func configureCellRegion(cell: UITableViewCell, withLuggageTag item: LuggageTag, connected: Bool) {
    let region = cell.viewWithTag(1002) as! CustomDetectionView
    if (connected) {
      region.image = UIImage(named: "in_range")
    } else {
      region.image = UIImage(named: "off_range")
    }
  }
  
  private func loadBeaconItems() {
    // Loop Through All BeaconItem and put it in Model
    for beacon in frc.fetchedObjects! as! [BeaconItem] {
      let item = LuggageTag()
      let index: Int = Int(beacon.id!)
      let i: Int = Int(beacon.connection!)
      var isConnected = false
      if (i == 1) {
        isConnected = true
      }
      
      item.id = index
      
      if beacon.photo != nil {
        item.photo = beacon.photo!
      }
      
      item.name = beacon.name!
      item.uuid = beacon.uuid!
      item.major = beacon.major!
      item.minor = beacon.minor!
      item.regionState = Constants.Proximity.Unknown
      item.isConnected = isConnected
      
      row.append(item)
    }
    
    // Reload TableView
    self.tableView.reloadData()
  }
  
  private func startMonitoring() {
    if row.count > 0 {
      for beacon in row {
        if beacon.isConnected {
          var beaconRegion: CLBeaconRegion?
          beaconRegion = CLBeaconRegion(proximityUUID: NSUUID(UUIDString: beacon.uuid)!, identifier: beacon.name)
          // Stop Beacon First
          tktCoreLocation.stopMonitoringBeacon(beaconRegion, removeObject: false)
  
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
  
  private func startMonitoringforBeacon(beaconItem: LuggageTag) {
    var beaconRegion: CLBeaconRegion?
    beaconRegion = CLBeaconRegion(proximityUUID: NSUUID(UUIDString: beaconItem.uuid)!, identifier: beaconItem.name)
    // later, these values can be set from the UI
    beaconRegion!.notifyEntryStateOnDisplay = true
    beaconRegion!.notifyOnEntry = true
    beaconRegion!.notifyOnExit = true
    
    tktCoreLocation.startMonitoring(beaconRegion)
  }
  
  private func checkLuggageTagRegion() {
    if row.count > 0 {
      for beacon in row {
        if (beacon.regionState == Constants.Proximity.Inside) {
          // Stop Monitoring for this Beacon
          var beaconRegion: CLBeaconRegion?
          beaconRegion = CLBeaconRegion(proximityUUID: NSUUID(UUIDString: beacon.uuid)!, identifier: beacon.name)
          
          // Stop Monitoring this Specific Beacon.
          tktCoreLocation.stopMonitoringBeacon(beaconRegion, removeObject: false)
          
          if let index = row.indexOf(beacon) {
            let indexPath = NSIndexPath(forRow: index, inSection: 0)
            row[indexPath.row].regionState = Constants.Proximity.Outside
            
            if let cell = tableView.cellForRowAtIndexPath(indexPath) {
              configureCellRegion(cell, withLuggageTag: beacon, connected: false)
            }
          }
        }
      }
    }
  }
  
  private func getMaxID() -> Int {
    
    if row.count > 0 {
      var ids = [Int]()
      
      for luggage in row {
        ids.append(luggage.id)
      }
      
      return ids.maxElement()!
    }

    return 0
  }
  
  private func saveToDatabase(beaconItem: LuggageTag) {
    let entityDescription = NSEntityDescription.entityForName("BeaconItem", inManagedObjectContext: moc)
    
    let item = BeaconItem(entity: entityDescription!, insertIntoManagedObjectContext: moc)
    let id = NSNumber(integer: beaconItem.id)
    
    item.id = id
    item.photo = beaconItem.photo
    item.name = beaconItem.name
    item.uuid = beaconItem.uuid
    item.major = beaconItem.major
    item.minor = beaconItem.minor
    item.connection = beaconItem.isConnected
    
    do {
      try moc.save()
      Globals.log("Saved Successfuly to Database")
    } catch let error as NSError{
      fatalError("Failed to saving to Database : \(error)")
    }
  }
  
  private func updateToDatabase(item: LuggageTag) {
    let entityDescription = NSEntityDescription.entityForName("BeaconItem", inManagedObjectContext: moc)
    
    let req = NSFetchRequest()
    req.entity = entityDescription
    let index = "\(item.id)"
    
    let condition = NSPredicate(format: "id == \(index)")
    
    req.predicate = condition
    
    do {
      let result = try moc.executeFetchRequest(req)
      
      if result.count > 0 {
        let beacon = result[0] as! BeaconItem
        beacon.setValue(item.photo, forKey: "photo")
        beacon.setValue(item.name, forKey: "name")
        beacon.setValue(item.uuid, forKey: "uuid")
        beacon.setValue(item.major, forKey: "major")
        beacon.setValue(item.minor, forKey: "minor")
        beacon.setValue(item.isConnected, forKey: "connection")
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
  
  private func deleteToDatabase(id: Int) {
    let entityDescription = NSEntityDescription.entityForName("BeaconItem", inManagedObjectContext: moc)
    
    let req = NSFetchRequest()
    req.entity = entityDescription
    let index = "\(id)"
    
    let condition = NSPredicate(format: "id == \(index)")
    
    req.predicate = condition

    do {
      let result = try moc.executeFetchRequest(req) as? [NSManagedObject]
      
      if let res = result {
        if res.count > 0 {
          moc.deleteObject(res[0])
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
  
  private func updateCoreDataModel() {
    do {
      // Refetch FRC to make sure it is the new CoreData
      try frc.performFetch()
      
      for luggage in row {
        for beacon in frc.fetchedObjects as! [BeaconItem] {
          if (luggage.uuid == beacon.uuid!) {
            if (luggage.id != beacon.id!) {
              beacon.id = luggage.id
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
  
  private func createLocalNotification(name: String, identifier: String, message: String) {
    let localNotification = UILocalNotification()
    
    localNotification.fireDate = NSDate(timeIntervalSinceNow: 1)
    //localNotification.applicationIconBadgeNumber = 1
    localNotification.soundName = UILocalNotificationDefaultSoundName
    
    localNotification.userInfo = ["name" : name, "identifier": identifier]
    localNotification.alertBody = "Your Bag \(name) \(message)"
    
    UIApplication.sharedApplication().scheduleLocalNotification(localNotification)
  }
  
  private func deleteLocalNotification(name: String, identifier: String) {
    let scheduledNotifications: NSArray = UIApplication.sharedApplication().scheduledLocalNotifications!
    
    if(scheduledNotifications.count > 0) {
      for  notification in scheduledNotifications {
        let n = notification as! UILocalNotification
        let notifName = n.userInfo!["name"] as! String
        let notifIdentifier = n.userInfo!["identifier"] as! String
        
        if (name == notifName && identifier == notifIdentifier) {
          UIApplication.sharedApplication().cancelLocalNotification(n)
        }
      }
    }
  }
  
  private func formatNavigationBar() {
    self.navigationController?.navigationBar.setBackgroundImage(UIImage(), forBarMetrics: .Default)
    self.navigationController?.navigationBar.shadowImage = UIImage()
    self.navigationController?.navigationBar.translucent = true
  
    self.tableView.contentInset = UIEdgeInsetsMake(150.0, 0, 0, 0)
  }
  
  private func applicationInfo() {
    appInfoView.alpha = 0.6
    if let version = NSBundle.mainBundle().infoDictionary?["CFBundleShortVersionString"] as? String {
      versionLabel.text = "v\(version)"
    }
    companyLabel.text = NSLocalizedString("tektos_limited", comment: "")
    rightsLabel.text = NSLocalizedString("alrights_reserved", comment: "")
  }
  
}



