//
//  DataSource.swift
//  DataSource
//
//  Created by Matthias Buchetics on 21/02/2017.
//  Copyright © 2017 aaa - all about apps GmbH. All rights reserved.
//

import Foundation
import Diff

public class DataSource: NSObject {
    
    public struct Item {
        let indexPath: IndexPath
        let row: RowType
    }
    
    public internal(set) var allSections: [SectionType] = []
    public internal(set) var visibleSections: [SectionType] = []

    public var isRowHidden: ((RowType, IndexPath) -> Bool)? = nil
    public var isSectionHidden: ((SectionType, Int) -> Bool)? = nil
    
    // MARK: UITableViewDataSource
    
    public var configure: ((RowType, UITableViewCell, IndexPath) -> Void)? = nil
    public var canEdit: ((RowType, IndexPath) -> Bool)? = nil
    public var canMove: ((RowType, IndexPath) -> Bool)? = nil
    public var sectionIndexTitles: (() -> [String]?)? = nil
    public var sectionForSectionIndex: ((String, Int) -> Int)? = nil
    public var commitEditing: ((RowType, UITableViewCellEditingStyle, IndexPath) -> Void)? = nil
    public var moveRow: ((RowType, (IndexPath, IndexPath)) -> Void)? = nil
    
    public var fallbackDataSource: UITableViewDataSource? = nil
    
    // MARK: UITableViewDelegate
    
    public var height: ((RowType, IndexPath) -> CGFloat)? = nil
    
    // no RowType parameter for estimatedHeight because we do not want to potentially instantiate
    // a LazyRow just to get the height estimate
    public var estimatedHeight: ((IndexPath) -> CGFloat)? = nil
    
    public var shouldHighlight: ((RowType, IndexPath) -> Bool)? = nil
    public var didHighlight: ((RowType, IndexPath) -> Void)? = nil
    public var didUnhighlight: ((RowType, IndexPath) -> Void)? = nil
    
    public var willSelect: ((RowType, IndexPath) -> IndexPath?)? = nil
    public var willDeselect: ((RowType, IndexPath) -> IndexPath?)? = nil
    public var didSelect: ((RowType, IndexPath) -> SelectionResult)? = nil
    public var didDeselect: ((RowType, IndexPath) -> Void)? = nil
    
    public var willDisplay: ((RowType, UITableViewCell, IndexPath) -> Void)? = nil
    public var didEndDisplaying: ((UITableViewCell, IndexPath) -> Void)? = nil
    
    public var editingStyle: ((RowType, IndexPath) -> UITableViewCellEditingStyle)? = nil
    public var titleForDeleteConfirmationButton: ((RowType, IndexPath) -> String?)? = nil
    public var editActions: ((RowType, IndexPath) -> [UITableViewRowAction]?)? = nil
    public var shouldIndentWhileEditing: ((RowType, IndexPath) -> Bool)? = nil
    public var willBeginEditing: ((RowType, IndexPath) -> Void)? = nil
    public var didEndEditing: ((RowType?, IndexPath?) -> Void)? = nil
    
    public var sectionHeader: ((SectionType, Int) -> HeaderFooter)? = nil
    public var sectionFooter: ((SectionType, Int) -> HeaderFooter)? = nil
    
    public var sectionHeaderHeight: ((SectionType, Int) -> SectionHeight)? = nil
    public var sectionFooterHeight: ((SectionType, Int) -> SectionHeight)? = nil
    
    public var willDisplaySectionHeader: ((SectionType, UIView, Int) -> Void)? = nil
    public var willDisplaySectionFooter: ((SectionType, UIView, Int) -> Void)? = nil
    
    public var didEndDisplayingSectionHeader: ((UIView, Int) -> Void)? = nil
    public var didEndDisplayingSectionFooter: ((UIView, Int) -> Void)? = nil
    
    public var targetIndexPathForMove: ((RowType, (IndexPath, IndexPath)) -> IndexPath)? = nil
    public var indentationLevel: ((RowType, IndexPath) -> Int)? = nil
    public var shouldShowMenu: ((RowType, IndexPath) -> Bool)? = nil
    public var canPerformAction: ((RowType, Selector, Any?, IndexPath) -> Bool)? = nil
    public var performAction: ((RowType, Selector, Any?, IndexPath) -> Void)? = nil
    public var canFocus: ((RowType, IndexPath) -> Bool)? = nil
    
    public var fallbackDelegate: UITableViewDelegate? = nil
    
    // MARK: UITableViewDataSourcePrefetching
    
    public var prefetchRows: (([IndexPath]) -> Void)? = nil
    public var cancelPrefetching: (([IndexPath]) -> Void)? = nil
    
    public var fallbackDataSourcePrefetching: UITableViewDataSourcePrefetching? = nil
    
    // MARK: Internal
    
    var cellDescriptors: [String: CellDescriptorType] = [:]
    var reuseIdentifiers: Set<String> = []
    let registerNibs: Bool
    
    // MARK: Init
    
    public init(_ cellDescriptors: [CellDescriptorType], registerNibs: Bool = true) {
        self.registerNibs = registerNibs
        
        for d in cellDescriptors {
            self.cellDescriptors[d.rowIdentifier] = d
        }
        
        super.init()
    }
    
    // MARK: Getters & Setters
    
    public var sections: [SectionType] {
        get {
            return allSections
        }
        set {
            allSections = newValue
            updateVisibility()
        }
    }
    
    public func section(at index: Int) -> SectionType {
        return allSections[index]
    }
    
    public func row(at indexPath: IndexPath) -> RowType {
        return allSections[indexPath.section].row(at: indexPath.row)
    }
    
    public func visibleSection(at index: Int) -> SectionType {
        return visibleSections[index]
    }
    
    public func visibleRow(at indexPath: IndexPath) -> RowType {
        return visibleSections[indexPath.section].visibleRow(at: indexPath.row)
    }
    
    // MARK: Cell Descriptors
    
    public func cellDescriptor(at indexPath: IndexPath) -> CellDescriptorType {
        let row = visibleRow(at: indexPath)
        
        if let cellDescriptor = cellDescriptors[row.identifier] {
            return cellDescriptor
        } else {
            fatalError("[DataSource] no cellDescriptor found for indexPath \(indexPath)")
        }
    }
    
    public func cellDescriptor(for rowIdentifier: String) -> CellDescriptorType {
        if let cellDescriptor = cellDescriptors[rowIdentifier] {
            return cellDescriptor
        } else {
            fatalError("[DataSource] no cellDescriptor found for rowIdentifier \(rowIdentifier)")
        }
    }
    
    // MARK: Updates
    
    public func replace(key: String? = nil, section: SectionType) {
        if let index = sections.index(where: { $0.key == key ?? section.key }) {
            self.sections[index] = section
        }
    }
    
    // MARK: Visibility
    
    public func update(sections: [SectionType]? = nil, tableView: UITableView) {
        if let sections = sections {
            self.allSections = sections
        }
        
        self.visibleSections = updateSectionVisiblity()
        tableView.reloadData()
    }
    
    internal func updateVisibility() {
        self.visibleSections = updateSectionVisiblity()
    }
    
    internal func updateSectionVisiblity() -> [SectionType] {
        var visibleSections = [SectionType]()
        
        for (sectionIndex, section) in allSections.enumerated() {
            section.updateVisibility(sectionIndex: sectionIndex, dataSource: self)
            
            let isHidden = section.isHiddenClosure?(section, sectionIndex) ?? isSectionHidden?(section, sectionIndex) ?? false
            
            if !isHidden && section.numberOfVisibleRows > 0 {
                visibleSections.append(section)
            }
        }
        
        return visibleSections
    }    
}
