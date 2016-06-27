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

class ListViewController: UIViewController, CBCentralManagerDelegate, TKTCoreLocationDelegate, UITableViewDataSource,
UITableViewDelegate, BeaconDetailViewControllerDelegate, NSFetchedResultsControllerDelegate, CustomTableCellDelegate  {
  
  var row: [BeaconModel]
  
  let moc = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext
  
  var frc: NSFetchedResultsController = NSFetchedResultsController()
  
  @IBOutlet var tableView: UITableView!
  @IBOutlet weak var topLogoView: UIView!
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
    row = [BeaconModel]()
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
    } catch {
      print("Failed to perform initial fecth.")
    }
    
    loadBeaconItems()
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
  
  func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
    tableView.deselectRowAtIndexPath(indexPath, animated: true)
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
    let alertController = UIAlertController(
      title: NSLocalizedString("location_access_disabled", comment: ""),
      message: NSLocalizedString("location_access_disabled_settings", comment: ""),
      preferredStyle: .Alert)
    
    alertController.addAction(UIAlertAction(title: NSLocalizedString("cancel", comment: ""), style: .Cancel, handler: nil))
    
    alertController.addAction(
      UIAlertAction(title: NSLocalizedString("settings", comment: ""), style: .Default) { (action) in
        if let url = NSURL(string:UIApplicationOpenSettingsURLString) {
          UIApplication.sharedApplication().openURL(url)
        }
      })
    self.presentViewController(alertController, animated: true, completion: nil)
  }
  
  func didStartMonitoring() {
    isMonitoring = true
  }
  
  
  func didStopMonitoring() {
    isMonitoring = false
  }
  
  func monitoringDidFail() {}
  
  func didEnterRegion(region: CLRegion!) {
    for beacon in row {
      if (beacon.name == region.identifier) {
        if (beacon.proximity != Constants.Proximity.Inside) {
          beacon.proximity = Constants.Proximity.Inside
          if let index = row.indexOf(beacon) {
            let indexPath = NSIndexPath(forRow: index, inSection: 0)
            if let cell = tableView.cellForRowAtIndexPath(indexPath) {
              configureCellRegion(cell, withBeaconModel: beacon, connected: true)
              createLocalNotification(region.identifier, identifier: beacon.UUID, message: NSLocalizedString("has_arrived", comment: ""))
            }
          }
        }
      }
    }
  }
  
  func didExitRegion(region: CLRegion!) {
    for beacon in row {
      if (beacon.name == region.identifier) {
        if (beacon.proximity != Constants.Proximity.Outside) {
          beacon.proximity = Constants.Proximity.Outside
          if let index = row.indexOf(beacon) {
            let indexPath = NSIndexPath(forRow: index, inSection: 0)
            if let cell = tableView.cellForRowAtIndexPath(indexPath) {
              configureCellRegion(cell, withBeaconModel: beacon, connected: false)
              createLocalNotification(region.identifier, identifier: beacon.UUID, message: NSLocalizedString("is_gone", comment: ""))
            }
          }
          
        }
      }
    }
  }
  
  func didRangeBeacon(manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], inRegion region: CLBeaconRegion) {
   /* print("*****************************")
    print("BEACONS \(beacons)")
    print("REGION \(region)")
    print("REGION \(manager)")
    print("*****************************")
    
    for beacon in row {
      for clBeacon in beacons {
        if beacon.UUID == clBeacon.proximityUUID.UUIDString {
          print("New Update for \(clBeacon.proximityUUID.UUIDString)")
          
          switch (clBeacon.proximity) {
          case CLProximity.Far:
            if (beacon.proximity != "Far") {
              beacon.proximity = "Far"
            }
          case CLProximity.Near:
            if (beacon.proximity != "Near") {
              beacon.proximity = "Near"
            }
          case CLProximity.Immediate:
            if (beacon.proximity != "Immediate") {
              beacon.proximity = "Immediate"
            }
          case CLProximity.Unknown:
            if (beacon.proximity != "unknown") {
              beacon.proximity = "unknown"
            }
          }
          
        }
      }
    }*/
  }
  
  // MARK: BeaconDetailViewControllerDelegate Methods
  func beaconDetailViewController(controller: BeaconDetailViewController, didFinishAddingItem item: BeaconModel) {
    let index = row.count
    row.append(item)
    item.id = index
    
    let indexPath = NSIndexPath(forRow: index, inSection: 0)
    let indexPaths = [indexPath]
    
    tableView.beginUpdates()
    tableView.insertRowsAtIndexPaths(indexPaths, withRowAnimation: .Automatic)
    tableView.endUpdates()
    
    // Save item in Database
    saveToDatabase(item)

    dismissViewControllerAnimated(true, completion: nil)
  }
  
  func beaconDetailViewController(controller: BeaconDetailViewController, didFinishEditingItem item: BeaconModel) {
    if let index = row.indexOf(item) {
      let indexPath = NSIndexPath(forRow: index, inSection: 0)
      if let cell = tableView.cellForRowAtIndexPath(indexPath) {
        configureCell(cell, withBeaconModel: item)
        configureCellRegion(cell, withBeaconModel: item, connected: false)
      }
      
      if (item.isConnected) {
        startMonitoringforBeacon(item)
      }
      
      updateToDatabase(item)
    }
  
    dismissViewControllerAnimated(true, completion: nil)
  }
  
  func deleteBeacon(didDeleteItem item: BeaconModel) {
    if let index = row.indexOf(item) {
      // Check if item is monitoring
      if item.isConnected {
        // Stop Monitoring for this Beacon
        var beaconRegion: CLBeaconRegion?
        beaconRegion = CLBeaconRegion(proximityUUID: NSUUID(UUIDString: item.UUID)!, identifier: item.name)
        
        tktCoreLocation.stopMonitoringBeacon(beaconRegion)
      }
      
      // Delete LocalNotification
      deleteLocalNotification(item.name, identifier: item.UUID)
      
      deleteToDatabase(item.id)
      
      row.removeAtIndex(index)
      let indexPath = NSIndexPath(forRow: index, inSection: 0)
      let indexPaths = [indexPath]
      
      tableView.beginUpdates()
      tableView.deleteRowsAtIndexPaths(indexPaths, withRowAnimation: .Automatic)
      tableView.endUpdates()
    }
    
    dismissViewControllerAnimated(true, completion: nil)
  }
  
  func didBluetoothPoweredOff(didPowerOff item: BeaconModel) {
    if let index = row.indexOf(item) {
      let indexPath = NSIndexPath(forRow: index, inSection: 0)
      if let cell = tableView.cellForRowAtIndexPath(indexPath) {
        configureCellRegion(cell, withBeaconModel: item, connected: false)
      }
    }
  }
  
  // MARK: CustomTableCellDelegate
  func didTappedSwitchCell(cell: CustomTableCell) {
    let indexPath = tableView.indexPathForCell(cell)
    let isConnected = cell.customSwitch.on ? false : true;
    let item = row[(indexPath?.row)!]
    item.isConnected = isConnected
    
    row[(indexPath?.row)!].proximity = Constants.Proximity.Outside
    
    if isConnected {
      if (!isBluetoothPoweredOn) {
        showAlertForSettings()
      }
      
      // Start Monitoring for this Beacon
      var beaconRegion: CLBeaconRegion?
      beaconRegion = CLBeaconRegion(proximityUUID: NSUUID(UUIDString: item.UUID)!, identifier: item.name)
      // later, these values can be set from the UI
      beaconRegion!.notifyEntryStateOnDisplay = true
      beaconRegion!.notifyOnEntry = true
      beaconRegion!.notifyOnExit = true
      
      tktCoreLocation.startMonitoring(beaconRegion)
    } else {
      // Delete LocalNotification
      deleteLocalNotification(row[(indexPath?.row)!].name, identifier: row[(indexPath?.row)!].UUID)
      
      row[(indexPath?.row)!].proximity = Constants.Proximity.Outside
      configureCellRegion(cell, withBeaconModel: item, connected: false)
      
      // Stop Monitoring for this Beacon
      var beaconRegion: CLBeaconRegion?
      beaconRegion = CLBeaconRegion(proximityUUID: NSUUID(UUIDString: item.UUID)!, identifier: item.name)
      
      // Stop Monitoring this Specific Beacon.
      tktCoreLocation.stopMonitoringBeacon(beaconRegion)
    }
    
    updateToDatabase(item)
  }
  
  // MARK: Private Methods
  private func showAlertForSettings() {
    let alertController = UIAlertController(title: NSLocalizedString("app_name", comment: ""), message: NSLocalizedString("turn_on_bluetooth", comment: ""), preferredStyle: .Alert)
    
    let cancelAction = UIAlertAction(title: NSLocalizedString("settings", comment: ""), style: .Cancel) { (action) in
      if let url = NSURL(string:UIApplicationOpenSettingsURLString) {
        UIApplication.sharedApplication().openURL(url)
      }
    }
    alertController.addAction(cancelAction)
    
    let okAction = UIAlertAction(title: NSLocalizedString("ok", comment: ""), style: .Default, handler: nil)
    alertController.addAction(okAction)
    
    self.presentViewController(alertController, animated: true, completion: nil)
  }
  
  private func configureCell(cell: UITableViewCell, withBeaconModel item: BeaconModel) {
    let label = cell.viewWithTag(1000) as! UILabel
    let photo = cell.viewWithTag(1001) as! CustomButton
    
    if (item.photo != nil) {
      photo.setImage(UIImage(data: item.photo!)!, forState: .Normal)
      photo.imageView?.contentMode = UIViewContentMode.Center
    }
    
    label.text = item.name
  }
  
  private func configureCellRegion(cell: UITableViewCell, withBeaconModel item: BeaconModel, connected: Bool) {
    let region = cell.viewWithTag(1002) as! DesignableView
    if (connected) {
      region.image = UIImage(named: "in_range")
    } else {
      region.image = UIImage(named: "off_range")
    }
  }
  
  private func loadBeaconItems() {
    // Loop Through All BeaconItem and put it in Model
    for beacon in frc.fetchedObjects! as! [BeaconItem] {
      let item = BeaconModel()
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
      item.UUID = beacon.uuid!
      item.major = beacon.major!
      item.minor = beacon.minor!
      item.proximity = Constants.Proximity.Unknown
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
          beaconRegion = CLBeaconRegion(proximityUUID: NSUUID(UUIDString: beacon.UUID)!, identifier: beacon.name)
          // Stop Beacon First
          tktCoreLocation.stopMonitoringBeacon(beaconRegion)
  
          // later, these values can be set from the UI
          beaconRegion!.notifyEntryStateOnDisplay = true
          beaconRegion!.notifyOnEntry = true
          beaconRegion!.notifyOnExit = true
          
          tktCoreLocation.startMonitoring(beaconRegion)
        } else {
          print("\(beacon.name) is disabled")
        }
      }
    } else {
      print("No Beacon Available")
    }
  }
  
  private func startMonitoringforBeacon(beaconItem: BeaconModel) {
    var beaconRegion: CLBeaconRegion?
    beaconRegion = CLBeaconRegion(proximityUUID: NSUUID(UUIDString: beaconItem.UUID)!, identifier: beaconItem.name)
    // later, these values can be set from the UI
    beaconRegion!.notifyEntryStateOnDisplay = true
    beaconRegion!.notifyOnEntry = true
    beaconRegion!.notifyOnExit = true
    
    tktCoreLocation.startMonitoring(beaconRegion)
  }
  
  private func checkLuggageTagRegion() {
    if row.count > 0 {
      for beacon in row {
        if (beacon.proximity == Constants.Proximity.Inside) {
          // Stop Monitoring for this Beacon
          var beaconRegion: CLBeaconRegion?
          beaconRegion = CLBeaconRegion(proximityUUID: NSUUID(UUIDString: beacon.UUID)!, identifier: beacon.name)
          
          // Stop Monitoring this Specific Beacon.
          tktCoreLocation.stopMonitoringBeacon(beaconRegion)
          
          if let index = row.indexOf(beacon) {
            let indexPath = NSIndexPath(forRow: index, inSection: 0)
            row[indexPath.row].proximity = Constants.Proximity.Outside
            
            if let cell = tableView.cellForRowAtIndexPath(indexPath) {
              configureCellRegion(cell, withBeaconModel: beacon, connected: false)
            }
          }
        }
      }
    }
  }
  
  private func saveToDatabase(beaconItem: BeaconModel) {
    let entityDescription = NSEntityDescription.entityForName("BeaconItem", inManagedObjectContext: moc)
    
    let item = BeaconItem(entity: entityDescription!, insertIntoManagedObjectContext: moc)
    let id = NSNumber(integer: beaconItem.id)
    
    item.id = id
    item.photo = beaconItem.photo
    item.name = beaconItem.name
    item.uuid = beaconItem.UUID
    item.major = beaconItem.major
    item.minor = beaconItem.minor
    item.connection = beaconItem.isConnected
    
    do {
      try moc.save()
      print("Saved Successfuly to Database")
    } catch let error as NSError{
      fatalError("Failed to saving to Database : \(error)")
    }
  }
  
  private func updateToDatabase(item: BeaconModel) {
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
        beacon.setValue(item.UUID, forKey: "uuid")
        beacon.setValue(item.isConnected, forKey: "connection")
        do {
          try moc.save()
          print("Successfully Updated Database")
        } catch let error as NSError{
          fatalError("Failed to updating to Database : \(error)")
        }
      } else {
        print("No Record Found")
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
            print("Successfully Deleted Item")
          } catch let error as NSError{
            fatalError("Failed to Delete Item : \(error)")
          }
        }
      }
    } catch let error as NSError {
      fatalError("Error: \(error)")
    }
  }
  
  private func createLocalNotification(name: String, identifier: String, message: String) {
    let localNotification = UILocalNotification()
    
    localNotification.fireDate = NSDate(timeIntervalSinceNow: 1)
    localNotification.applicationIconBadgeNumber = 1
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
    
    
    let topColor = UIColor.blackColor().colorWithAlphaComponent(0.4).CGColor
    let bottomColor = UIColor.clearColor().CGColor
    
    let gradientColors: [CGColor] = [topColor, bottomColor]
    let gradientLocations: [CGFloat] = [0.0, 1.0]
    
    let gradientLayer = CAGradientLayer()
    gradientLayer.colors = gradientColors
    gradientLayer.locations = gradientLocations
    
    gradientLayer.frame = self.topLogoView.bounds
    self.topLogoView.layer.insertSublayer(gradientLayer, atIndex: 0)
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



