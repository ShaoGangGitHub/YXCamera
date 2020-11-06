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
        weak var weakSelf = self
        let text:String = self.label.text ?? ""
        let image:UIImage = self.imageView.image ?? UIImage.init(named: "timg")!
        self.contentView.isUserInteractionEnabled = false
        DispatchQueue.global().async {
            let newImage = YXFilter.filterToImage(filterName: text, image: image) { (filter, ciimage) in
                if filter.inputKeys.contains("inputImage") {
                    filter.setValue(ciimage, forKey: "inputImage")
                }
            }
            DispatchQueue.main.async {
                if newImage == nil {
                    weakSelf?.imageView.image = UIImage.init(named: "timg")
                } else {
                    weakSelf?.imageView.image = newImage
                }
                weakSelf?.contentView.isUserInteractionEnabled = true
            }
        }
    }

}
