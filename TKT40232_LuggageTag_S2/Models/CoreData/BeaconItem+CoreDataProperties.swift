//
//  BeaconItem+CoreDataProperties.swift
//  TKT40232_LuggageTag_S2
//
//  Created by PhTktimac1 on 09/01/2017.
//  Copyright © 2017 Tektos Limited. All rights reserved.
//

import Foundation
import CoreData


extension BeaconItem {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<BeaconItem> {
        return NSFetchRequest<BeaconItem>(entityName: "BeaconItem");
    }

    @NSManaged public var connection: NSNumber?
    @NSManaged public var id: NSNumber?
    @NSManaged public var major: String?
    @NSManaged public var minor: String?
    @NSManaged public var name: String?
    @NSManaged public var photo: NSData?
    @NSManaged public var uuid: String?
    @NSManaged public var activation_code: String?
    @NSManaged public var activation_key: String?
    @NSManaged public var activated: NSNumber?

}
