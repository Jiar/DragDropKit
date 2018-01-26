//
//  ViewController.swift
//  Example
//
//  Created by Jiar on 20/01/2018.
//  Copyright © 2018 Jiar. All rights reserved.
//

import UIKit
import DragDropKit

class ViewController: UIViewController {

    @IBOutlet weak var tableView: DDTableView!
    
    var dataArray: [Array<String>] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        dataArray = [
            ["a", "b", "c", "d", "e"],
            ["f", "g", "h", "i", "j", "k", "l", "m", "n"],
            ["o", "p", "q"],
            ["r", "s", "t"],
            ["u", "v", "w", "x", "y", "z"]
        ]
    }

}

extension ViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return dataArray.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataArray[section].count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ExampleTableViewCell", for: indexPath) as! ExampleTableViewCell
        let section = indexPath.section
        let row = indexPath.row
        let value = dataArray[section][row]
        cell.config(title: "section: \(section) - row: \(row) - value: \(value)")
        return cell
    }
    
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let sourceSection = sourceIndexPath.section
        let sourceRow = sourceIndexPath.row
        let destinationSection = destinationIndexPath.section
        let destinationRow = destinationIndexPath.row
        if sourceSection == destinationSection {
            let sourceValue = dataArray[sourceSection][sourceRow]
            dataArray[sourceSection][sourceRow] = dataArray[destinationSection][destinationRow]
            dataArray[destinationSection][destinationRow] = sourceValue
        } else {
            let sourceValue = dataArray[sourceSection].remove(at: sourceRow)
            dataArray[destinationSection].insert(sourceValue, at: destinationRow)
        }
    }
}

extension ViewController: UITableViewDelegate {
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 54
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 31
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if section == dataArray.count-1 {
            return 31
        }
        return 0.01
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: 33))
        view.backgroundColor = .white
        let separatorView = UIView(frame: CGRect(x: 15, y: 15, width: tableView.frame.width-30, height: 1))
        separatorView.backgroundColor = UIColor(red: 230/255.0, green: 230/255.0, blue: 230/255.0, alpha: 1.0)
        view.addSubview(separatorView)
        return view
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        if section == dataArray.count-1 {
            let view = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: 33))
            view.backgroundColor = .white
            let separatorView = UIView(frame: CGRect(x: 15, y: 15, width: tableView.frame.width-30, height: 1))
            separatorView.backgroundColor = UIColor(red: 230/255.0, green: 230/255.0, blue: 230/255.0, alpha: 1.0)
            view.addSubview(separatorView)
            return view
        } else {
            return nil
        }
    }
    
}

