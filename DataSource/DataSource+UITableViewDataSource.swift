//
//  DataSource+UITableView.swift
//  DataSource
//
//  Created by Matthias Buchetics on 21/02/2017.
//  Copyright © 2017 aaa - all about apps GmbH. All rights reserved.
//

import UIKit
import Diff

extension DataSource: UITableViewDataSource {
    
    // MARK: Counts
    
    public func numberOfSections(in tableView: UITableView) -> Int {
        return visibleSections.count
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return visibleSections[section].numberOfVisibleRows
    }
    
    // MARK: Configuration
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellDescriptor = self.cellDescriptor(at: indexPath)
        let cellIdentifier = cellDescriptor.cellIdentifier
        
        if registerNibs && !reuseIdentifiers.contains(cellIdentifier) && Bundle.main.path(forResource: cellIdentifier, ofType: "nib") != nil {
            tableView.registerNib(cellDescriptor.cellClass)
            reuseIdentifiers.insert(cellIdentifier)
        }
       
        if let closure = cellDescriptor.configureClosure ?? configure {
            let row = self.visibleRow(at: indexPath)
            let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath)
            
            closure(row, cell, indexPath)
            
            return cell
        } else if let fallbackDataSource = fallbackDataSource {
            return fallbackDataSource.tableView(tableView, cellForRowAt: indexPath)
        } else {
            fatalError("[DataSource] no configure closure and no fallback UITableViewDataSource set")
        }
    }
    
    // MARK: Header & Footer
    
    public func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let index = section
        let section = visibleSections[index]
        
        switch section.headerClosure?(section, index) {
        case .title(let title)?:
            return title
        default:
            return nil
        }
    }
    
    public func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        let index = section
        let section = visibleSections[index]
        
        switch section.footerClosure?(section, index) {
        case .title(let title)?:
            return title
        default:
            return nil
        }
    }
    
    // MARK: Editing
    
    public func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        let cellDescriptor = self.cellDescriptor(at: indexPath)
        let row = self.visibleRow(at: indexPath)
        
        if let closure = cellDescriptor.canEditClosure ?? canEdit {
            return closure(row, indexPath)
        } else {
            return fallbackDataSource?.tableView?(tableView, canEditRowAt: indexPath) ?? false
        }
    }
    
    // MARK: Moving & Reordering
    
    public func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        let cellDescriptor = self.cellDescriptor(at: indexPath)
        let row = self.visibleRow(at: indexPath)
        
        if let closure = cellDescriptor.canMoveClosure ?? canMove {
            return closure(row, indexPath)
        } else {
            return fallbackDataSource?.tableView?(tableView, canMoveRowAt: indexPath) ?? false
        }
    }
    
    // MARK: Index
    
    public func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        return sectionIndexTitles?() ?? fallbackDataSource?.sectionIndexTitles?(for: tableView)
    }
    
    public func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
        return sectionForSectionIndex?(title, index) ?? fallbackDataSource?.tableView?(tableView, sectionForSectionIndexTitle: title, at: index) ?? index
    }
    
    // MARK: Data manipulation
    
    public func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        let cellDescriptor = self.cellDescriptor(at: indexPath)
        let row = self.visibleRow(at: indexPath)
        
        if let closure = cellDescriptor.commitEditingClosure ?? commitEditing {
            closure(row, editingStyle, indexPath)
        } else {
            fallbackDataSource?.tableView?(tableView, commit: editingStyle, forRowAt: indexPath)
        }
    }
    
    public func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let cellDescriptor = self.cellDescriptor(at: sourceIndexPath)
        let row = self.visibleRow(at: sourceIndexPath)
        
        if let closure = cellDescriptor.moveRowClosure ?? moveRow {
            closure(row, (sourceIndexPath, destinationIndexPath))
        } else {
            fallbackDataSource?.tableView?(tableView, moveRowAt: sourceIndexPath, to: destinationIndexPath)
        }
    }
}
