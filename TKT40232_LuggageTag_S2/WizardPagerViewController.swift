//
//  WizardPagerViewController.swift
//  TKT40232_LuggageTag_S2
//
//  Created by Edmer Alarte on 22/3/2017.
//  Copyright © 2017 Tektos Limited. All rights reserved.
//

import UIKit

class WizardPagerViewController: UIPageViewController {
    
    weak var pageViewdelegate: PageViewControllerDelegate?
    
    fileprivate(set) lazy var orderedViewControllers: [UIViewController] = {
        // The view controllers will be shown in this order
        return [self.newColoredViewController("Green"),
                self.newColoredViewController("Red"),
                self.newColoredViewController("Blue"),
                self.newColoredViewController("NameYourTag"),
                self.newColoredViewController("AddPhoto"),
                
                ]
    }()
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // dataSource = self
        delegate = self
        
        if let initialViewController = orderedViewControllers.first {
            scrollToViewController(initialViewController)
        }
        
        pageViewdelegate?.pageViewControllerObject(self, didUpdatePageCount: orderedViewControllers.count)
        
    }
    
    
    func scrollToNextViewController() {
        if let visibleViewController = viewControllers?.first,
            let nextViewController = pageViewController(self,
                                                        viewControllerAfter: visibleViewController) {
            scrollToViewController(nextViewController)
        }
    }
    
    func scrollToLastViewController() {
        if let visibleViewController = viewControllers?.first,
            let nextViewController = pageViewController(self,
                                                        viewControllerBefore: visibleViewController) {
            scrollBackToViewController(nextViewController)
        }
    }
    
    /**
     Scrolls to the view controller at the given index. Automatically calculates
     the direction.
     
     - parameter newIndex: the new index to scroll to
     */
    func scrollToViewController(index newIndex: Int) {
        if let firstViewController = viewControllers?.first,
            let currentIndex = orderedViewControllers.index(of: firstViewController) {
            let direction: UIPageViewControllerNavigationDirection = newIndex >= currentIndex ? .forward : .reverse
            let nextViewController = orderedViewControllers[newIndex]
            scrollToViewController(nextViewController, direction: direction)
        }
    }
    
    func scrollBackToViewController(index newIndex: Int) {
        if let firstViewController = viewControllers?.first,
            let currentIndex = orderedViewControllers.index(of: firstViewController) {
            let direction: UIPageViewControllerNavigationDirection = newIndex >= currentIndex ? .forward : .reverse
            let nextViewController = orderedViewControllers[newIndex]
            scrollBackToViewController(nextViewController, direction: direction)
        }
    }
    
    fileprivate func newColoredViewController(_ color: String) -> UIViewController {
        return UIStoryboard(name: "Main", bundle: nil) .
            instantiateViewController(withIdentifier: "\(color)ViewController")
    }
    
    /**
     Scrolls to the given 'viewController' page.
     
     - parameter viewController: the view controller to show.
     */
    fileprivate func scrollToViewController(_ viewController: UIViewController,
                                            direction: UIPageViewControllerNavigationDirection = .forward) {
        setViewControllers([viewController],
                           direction: direction,
                           animated: true,
                           completion: { (finished) -> Void in
                            // Setting the view controller programmatically does not fire
                            // any delegate methods, so we have to manually notify the
                            // 'delegate' of the new index.
                            self.notifyTutorialDelegateOfNewIndex()
        })
    }
    
    fileprivate func scrollBackToViewController(_ viewController: UIViewController,
                                                direction: UIPageViewControllerNavigationDirection = .reverse) {
        setViewControllers([viewController],
                           direction: direction,
                           animated: true,
                           completion: { (finished) -> Void in
                            // Setting the view controller programmatically does not fire
                            // any delegate methods, so we have to manually notify the
                            // 'delegate' of the new index.
                            self.notifyTutorialDelegateOfNewIndex()
        })
    }
    
    /**
     Notifies '_delegate' that the current page index was updated.
     */
    fileprivate func notifyTutorialDelegateOfNewIndex() {
        if let firstViewController = viewControllers?.first,
            let index = orderedViewControllers.index(of: firstViewController) {
            pageViewdelegate?.pageViewControllerObject(self,
                                                         didUpdatePageIndex: index)
        }
    }
    
    
    
}

// MARK: UIPageViewControllerDataSource

extension WizardPagerViewController: UIPageViewControllerDataSource {
    
    func pageViewController(_ pageViewController: UIPageViewController,
                            viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let viewControllerIndex = orderedViewControllers.index(of: viewController) else {
            return nil
        }
        
        let previousIndex = viewControllerIndex - 1
        
        // User is on the first view controller and swiped left to loop to
        // the last view controller.
        guard previousIndex >= 0 else {
            return orderedViewControllers.last
        }
        
        guard orderedViewControllers.count > previousIndex else {
            return nil
        }
        
        return orderedViewControllers[previousIndex]
    }
    
    func pageViewController(_ pageViewController: UIPageViewController,
                            viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let viewControllerIndex = orderedViewControllers.index(of: viewController) else {
            return nil
        }
        
        let nextIndex = viewControllerIndex + 1
        let orderedViewControllersCount = orderedViewControllers.count
        
        // User is on the last view controller and swiped right to loop to
        // the first view controller.
        guard orderedViewControllersCount != nextIndex else {
            return orderedViewControllers.first
        }
        
        guard orderedViewControllersCount > nextIndex else {
            return nil
        }
        
        return orderedViewControllers[nextIndex]
    }
    
}

extension WizardPagerViewController: UIPageViewControllerDelegate {
    
    func pageViewController(_ pageViewController: UIPageViewController,
                            didFinishAnimating finished: Bool,
                            previousViewControllers: [UIViewController],
                            transitionCompleted completed: Bool) {
        notifyTutorialDelegateOfNewIndex()
    }
    
}

protocol PageViewControllerDelegate: class {
    
    /**
     Called when the number of pages is updated.
     
     - parameter pageViewControllerObject: the TutorialPageViewController instance
     - parameter count: the total number of pages.
     */
    func pageViewControllerObject(_ pageViewControllerObject: WizardPagerViewController,
                                    didUpdatePageCount count: Int)
    
    /**
     Called when the current index is updated.
     
     - parameter pageViewControllerObject: the TutorialPageViewController instance
     - parameter index: the index of the currently visible page.
     */
    func pageViewControllerObject(_ pageViewControllerObject: WizardPagerViewController,
                                    didUpdatePageIndex index: Int)
    
}
