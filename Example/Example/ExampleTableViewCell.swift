//
//  ExampleTableViewCell.swift
//  Example
//
//  Created by Jiar on 20/01/2018.
//  Copyright © 2018 Jiar. All rights reserved.
//

import UIKit

class ExampleTableViewCell: UITableViewCell {

    @IBOutlet weak var titleLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func config(title: String) {
        titleLabel.text = title
    }

}
