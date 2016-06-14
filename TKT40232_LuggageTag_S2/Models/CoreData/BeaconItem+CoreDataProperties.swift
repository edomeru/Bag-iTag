//
//  BeaconItem+CoreDataProperties.swift
//  TKT40214_LuggageFinder_S1_iOS
//
//  Created by PhTktimac1 on 07/06/2016.
//  Copyright © 2016 Tektos Limited. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension BeaconItem {

    @NSManaged var connection: NSNumber?
    @NSManaged var id: NSNumber?
    @NSManaged var major: String?
    @NSManaged var minor: String?
    @NSManaged var name: String?
    @NSManaged var photo: NSData?
    @NSManaged var uuid: String?

}
