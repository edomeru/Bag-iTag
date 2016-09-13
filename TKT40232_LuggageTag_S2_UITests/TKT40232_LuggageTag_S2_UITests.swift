//
//  TKT40232_LuggageTag_S2_UITests.swift
//  TKT40232_LuggageTag_S2_UITests
//
//  Created by PhTktimac1 on 13/07/2016.
//  Copyright © 2016 Tektos Limited. All rights reserved.
//

import XCTest

extension XCUIElement {
  /**
   courtesy of bay.phillips http://stackoverflow.com/questions/32821880/ui-test-deleting-text-in-text-field
   Removes any current text in the field before typing in the new value
   - Parameter text: the text to enter into the field
   */
  func clearAndEnterText(text: String) -> Void {
    guard let stringValue = self.value as? String else {
      XCTFail("Tried to clear and enter text into a non string value")
      return
    }
    
    self.tap()
    
    var deleteString: String = ""
    for _ in stringValue.characters {
      deleteString += "\u{8}"
    }
    self.typeText(deleteString)
    
    self.typeText(text)
  }
}


class TKT40232_LuggageTag_S2_UITests: XCTestCase {
        
    override func setUp() {
        super.setUp()
        
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
        XCUIApplication().launch()

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
      // Use recording to get started writing UI tests.
      // Use XCTAssert and related functions to verify your tests produce the correct results.
      //sanitationTesting()
      //addLuggages()
      //deleteLuggages()
    }
  
    func sanitationTesting() {
      let app = XCUIApplication()
      app.launch()
      
      app.tables.buttons["add button"].tap()
      let app2 = app
      let luggagenameField = app2.textFields["Luggage Tag"]
      luggagenameField.tap()
      luggagenameField.typeText("LuggageTag")
      app2.buttons["Return"].tap()
      let identifierField = app2.textFields["uuid"]
      identifierField.tap()
      identifierField.typeText("888888888888")
      app2.buttons["Return"].tap()
      app2.buttons["Cancel"].tap()
      
      app.tables.buttons["add button"].tap()
      
      luggagenameField.tap()
      luggagenameField.typeText("LuggageTag")
      app2.buttons["Return"].tap()
      
      identifierField.tap()
      identifierField.typeText("888888888888")
      app2.buttons["Return"].tap()
      let backButton = app.navigationBars["LuggageFinder.BeaconDetailView"].buttons["back button"]
      backButton.tap()
      
      app.tables.buttons["add button"].tap()
      luggagenameField.tap()
      luggagenameField.typeText("LuggageTag")
      app2.buttons["Return"].tap()
      identifierField.tap()
      identifierField.typeText("777777777777")
      app2.buttons["Return"].tap()
      backButton.tap()
      
      let okButton = app.alerts["Error"].collectionViews.buttons["OK"]
      okButton.tap()
      
      luggagenameField.tap()
      luggagenameField.clearAndEnterText("LuggageTag2")
      app2.buttons["Return"].tap()
      
      identifierField.tap()
      identifierField.clearAndEnterText("888888888888")
      app2.buttons["Return"].tap()
      
      backButton.tap()
      okButton.tap()
      
      identifierField.tap()
      identifierField.clearAndEnterText("777777777777")
      app2.buttons["Return"].tap()
      backButton.tap()
      
      app.tables.buttons["add button"].tap()
      backButton.tap()
      okButton.tap()
      
      luggagenameField.tap()
      luggagenameField.typeText("LuggageTag3")
      app2.buttons["Return"].tap()
      
      
      identifierField.tap()
      identifierField.typeText("1234X6ABCDEF")
      app2.buttons["Return"].tap()
      backButton.tap()
      okButton.tap()
      
      identifierField.tap()
      identifierField.clearAndEnterText("123456ABCDEF")
      app2.buttons["Return"].tap()
      backButton.tap()
      
      let tablesQuery = app.tables
      tablesQuery.staticTexts["LuggageTag2"].tap()
      
      luggagenameField.tap()
      luggagenameField.clearAndEnterText("LuggageTag")
      app2.buttons["Return"].tap()
      
      identifierField.tap()
      identifierField.clearAndEnterText("888888888888")
      app2.buttons["Return"].tap()
      backButton.tap()
      okButton.tap()
      
      luggagenameField.tap()
      luggagenameField.clearAndEnterText("LuggageTag2Edit")
      app2.buttons["Return"].tap()
      
      identifierField.tap()
      identifierField.clearAndEnterText("77777777777A")
      app2.buttons["Return"].tap()
      backButton.tap()
      
      //Delete LuggageTags
      tablesQuery.staticTexts["LuggageTag"].tap()
      app.buttons["DELETE"].tap()
      
      tablesQuery.staticTexts["LuggageTag2Edit"].tap()
      app.buttons["DELETE"].tap()
      
      tablesQuery.staticTexts["LuggageTag3"].tap()
      app.buttons["DELETE"].tap()


    }
  
  func addLuggages() {
    let app = XCUIApplication()
    app.launch()
    
    app.tables.buttons["add button"].tap()
    let luggagenameField = app.textFields["Name"]
    luggagenameField.tap()
    luggagenameField.typeText("Bag1")
    app.buttons["Return"].tap()
    let identifierField = app.textFields["uuid"]
    identifierField.tap()
    identifierField.typeText("883314DB17F3")
    app.buttons["Return"].tap()
    
    let backButtonButton = app.navigationBars["LuggageFinder.BeaconDetailView"].buttons["back button"]
    backButtonButton.tap()
    
    app.tables.buttons["add button"].tap()
    luggagenameField.tap()
    luggagenameField.typeText("Bag2")
    app.buttons["Return"].tap()
    identifierField.tap()
    identifierField.typeText("E0C79D5FC29B")
    app.buttons["Return"].tap()
    
    backButtonButton.tap()
    
    app.tables.buttons["add button"].tap()
    luggagenameField.tap()
    luggagenameField.typeText("Bag3")
    app.buttons["Return"].tap()
    identifierField.tap()
    identifierField.typeText("E0C79D5FBE51")
    app.buttons["Return"].tap()
    
    backButtonButton.tap()
    
    app.tables.buttons["add button"].tap()
    luggagenameField.tap()
    luggagenameField.typeText("Bag4")
    app.buttons["Return"].tap()
    identifierField.tap()
    identifierField.typeText("9C6AFF26DD05")
    app.buttons["Return"].tap()
    
    backButtonButton.tap()
    
    app.tables.buttons["add button"].tap()
    luggagenameField.tap()
    luggagenameField.typeText("Bag5")
    app.buttons["Return"].tap()
    identifierField.tap()
    identifierField.typeText("9C6AFF26DD06")
    app.buttons["Return"].tap()
    
    backButtonButton.tap()

  }
  
  func deleteLuggages() {
    let app = XCUIApplication()
    
    let tablesQuery = app.tables
    let table = tablesQuery.element
    table.swipeDown()
    table.swipeDown()
    
    app.tables.staticTexts["Bag1"].swipeLeft()
    app.tables.buttons["Delete"].tap()
    
    let removeButton = app.alerts["Delete Luggage Tag"].collectionViews.buttons["Remove"]
    removeButton.tap()
    
    app.tables.staticTexts["Bag2"].swipeLeft()
    app.tables.buttons["Delete"].tap()
    removeButton.tap()
    
    app.tables.staticTexts["Bag3"].swipeLeft()
    app.tables.buttons["Delete"].tap()
    removeButton.tap()
    
    app.tables.staticTexts["Bag4"].swipeLeft()
    app.tables.buttons["Delete"].tap()
    removeButton.tap()
    
    app.tables.staticTexts["Bag5"].swipeLeft()
    app.tables.buttons["Delete"].tap()
    removeButton.tap()
  }
}
