//
//  FilterCollectionViewCell.swift
//  YXTools
//
//  Created by shg on 2020/11/4.
//

import UIKit
import YXToolSDK

class FilterCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var label: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        
        let tap = UITapGestureRecognizer.init(target: self, action: #selector(tapAction(sender:)))
        self.contentView.addGestureRecognizer(tap)
    }
    
    @objc func tapAction(sender:UITapGestureRecognizer) {
        let newImage = YXFilter.filterToImage(filterName: self.label.text!, image: self.imageView.image!)
        if newImage == nil {
            self.imageView.image = UIImage.init(named: "timg")
        } else {
            self.imageView.image = newImage
        }
    }

}
