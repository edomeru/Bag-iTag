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
    startMonitoring()
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
    //configureCell(cell, withBeaconModel: item)
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
    case .PoweredOff:
      isBluetoothPoweredOn = false
      showAlertForSettings()
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
  
  func didEnterRegion(region: CLRegion!) {
    for beacon in row {
      if (beacon.name == region.identifier) {
        if (beacon.proximity != Constants.Proximity.Inside) {
          beacon.proximity = Constants.Proximity.Inside
          if let index = row.indexOf(beacon) {
            let indexPath = NSIndexPath(forRow: index, inSection: 0)
            if let cell = tableView.cellForRowAtIndexPath(indexPath) {
              configureCellRegion(cell, withBeaconModel: beacon, connected: true)
              createLocalNotification(region.identifier, message: NSLocalizedString("has_arrived", comment: ""))
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
              createLocalNotification(region.identifier, message: NSLocalizedString("is_gone", comment: ""))
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
              //createLocalNotification(region.identifier, message: "Far")
            }
          case CLProximity.Near:
            if (beacon.proximity != "Near") {
              beacon.proximity = "Near"
              //createLocalNotification(region.identifier, message: "Near")
            }
          case CLProximity.Immediate:
            if (beacon.proximity != "Immediate") {
              beacon.proximity = "Immediate"
              //createLocalNotification(region.identifier, message: "Immediate")
            }
          case CLProximity.Unknown:
            if (beacon.proximity != "unknown") {
              beacon.proximity = "unknown"
             //createLocalNotification(region.identifier, message: "unknown")
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
    
    //startMonitoringforBeacon(item)
  }
  
  func beaconDetailViewController(controller: BeaconDetailViewController, didFinishEditingItem item: BeaconModel) {
    if let index = row.indexOf(item) {
      let indexPath = NSIndexPath(forRow: index, inSection: 0)
      if let cell = tableView.cellForRowAtIndexPath(indexPath) {
        configureCell(cell, withBeaconModel: item)
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
  
  // MARK: CustomTableCellDelegate
  func didTappedSwitchCell(cell: CustomTableCell) {
    let indexPath = tableView.indexPathForCell(cell)
    let isConnected = cell.customSwitch.on ? false : true;
    let item = row[(indexPath?.row)!]
    item.isConnected = isConnected
    
    if isConnected {
      // Start Monitoring for this Beacon
      var beaconRegion: CLBeaconRegion?
      beaconRegion = CLBeaconRegion(proximityUUID: NSUUID(UUIDString: item.UUID)!, identifier: item.name)
      // later, these values can be set from the UI
      beaconRegion!.notifyEntryStateOnDisplay = true
      beaconRegion!.notifyOnEntry = true
      beaconRegion!.notifyOnExit = true
      
      tktCoreLocation.startMonitoring(beaconRegion)
    } else {
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
    //let size = CGSize(width: 150, height: 150)
    let label = cell.viewWithTag(1000) as! UILabel
    let photo = cell.viewWithTag(1001) as! CustomButton
    //let photo = cell.viewWithTag(1001) as! DesignableView
    
    if (item.photo != nil) {
      //photo.image = scaleImage(UIImage(data: item.photo!)!, toSize: size)
      photo.setImage(UIImage(data: item.photo!)!, forState: .Normal)
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
  
  private func scaleImage(image: UIImage, toSize newSize: CGSize) -> (UIImage) {
    let newRect = CGRectIntegral(CGRectMake(0,0, newSize.width, newSize.height))
    UIGraphicsBeginImageContextWithOptions(newSize, false, 0)
    let context = UIGraphicsGetCurrentContext()
    CGContextSetInterpolationQuality(context, .High)
    let flipVertical = CGAffineTransformMake(1, 0, 0, -1, 0, newSize.height)
    CGContextConcatCTM(context, flipVertical)
    CGContextDrawImage(context, newRect, image.CGImage)
    let newImage = UIImage(CGImage: CGBitmapContextCreateImage(context)!)
    UIGraphicsEndImageContext()
    return newImage
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
      item.isConnected = isConnected
      
      row.append(item)
      //row.insert(item, atIndex: index)
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
  
  private func createLocalNotification(name: String, message: String) {
    let localNotification = UILocalNotification()
    
    localNotification.fireDate = NSDate(timeIntervalSinceNow: 1)
    localNotification.applicationIconBadgeNumber = 1
    localNotification.soundName = UILocalNotificationDefaultSoundName
    
    localNotification.userInfo = ["message" : "\(name) is \(message)"]
    localNotification.alertBody = "Your Bag \(name) \(message)"
    
    UIApplication.sharedApplication().scheduleLocalNotification(localNotification)
  }
  
  private func formatNavigationBar() {
    self.navigationController?.navigationBar.setBackgroundImage(UIImage(), forBarMetrics: .Default)
    self.navigationController?.navigationBar.shadowImage = UIImage()
    self.navigationController?.navigationBar.translucent = true
  
    let titleView = UIView(frame: CGRectMake(0, 0, 150, 99))
    let titleImageView = UIImageView(image: UIImage(named: "luggage_tag_logo"))
    
    let y: CGFloat = self.navigationController!.navigationBar.frame.size.height
    let x: CGFloat = (titleView.frame.width) / 2

    titleImageView.frame = CGRectMake(x, y, titleView.frame.width, titleView.frame.height)
    titleView.addSubview(titleImageView)
    navigationItem.titleView = titleView
  }
  
  private func applicationInfo() {
    if let version = NSBundle.mainBundle().infoDictionary?["CFBundleShortVersionString"] as? String {
      versionLabel.text = "v\(version)"
    }
    companyLabel.text = NSLocalizedString("tektos_limited", comment: "")
    rightsLabel.text = NSLocalizedString("alrights_reserved", comment: "")
  }
  
}



