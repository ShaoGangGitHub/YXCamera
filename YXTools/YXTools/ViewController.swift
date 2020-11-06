//
//  ViewController.swift
//  YXTools
//
//  Created by shg on 2020/10/27.
//

import UIKit
import YXToolSDK

class ViewController: UIViewController,UICollectionViewDelegate, UICollectionViewDataSource ,UICollectionViewDelegateFlowLayout {
    
    @IBOutlet weak var imageView1: UIImageView!
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    @IBOutlet weak var collectionViewHeight: NSLayoutConstraint!
    
    var startFrame:CGRect!
    
    var finishedFrame:CGRect!
    
    var array:Array<Dictionary<String,Any>> = []
    
    lazy var camView: YXCamera = {
        let camView = YXCamera.init(frame: CGRect(x: 60, y: 40, width: self.view.bounds.size.width - 120, height: self.view.bounds.size.width - 120))
        camView.layer.cornerRadius = (self.view.bounds.size.width - 120)/2
        camView.layer.masksToBounds = true
        return camView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.addSubview(self.camView)
        self.view.bringSubviewToFront(self.camView)
        self.startFrame = self.camView.frame
        self.finishedFrame = CGRect(x: self.view.bounds.size.width - 80, y: 40, width: 60, height: 60)
        
        self.collectionView.register(UINib.init(nibName: "FilterCollectionViewCell", bundle: Bundle.main), forCellWithReuseIdentifier: "FilterCollectionViewCell")
        self.collectionViewHeight.constant = 0
        
        let image = YXFilter.filterToCreatQrCode(qrContent: "sssdsdsajldnsjcxzncnxzjlkxnzkjlxmz", size: 200, codeType: .qr)
        self.imageView1.image = image
    }
    
    //拍照
    @IBAction func 拍照事件(_ sender: UIButton) {
        weak var weakSelf = self
        self.camView.start { [self] (image) in
            weakSelf?.imageView1.image = image
            UIImageWriteToSavedPhotosAlbum(image, weakSelf, #selector(saveImage(image:didFinishSavingWithError:contextInfo:)), nil)
            UIView.animate(withDuration: 0.25) {
                weakSelf?.camView.frame = (weakSelf?.finishedFrame)!
                weakSelf?.camView.layer.cornerRadius = (weakSelf?.finishedFrame.size.width)!/2;
            }
            weakSelf?.setArray(image: image)
        }
    }
    
    private func setArray(image:UIImage) {
        self.array.removeAll()
        let arr = YXFilter.filterNamesinCategory(category: kCICategoryBuiltIn)
        for name in arr {
            self.array.append(["name":name,"image":image])
        }
        self.collectionView.reloadData()
    }
    
    @objc func saveImage(image: UIImage, didFinishSavingWithError error: NSError?, contextInfo: AnyObject) {
        if error != nil{
            print("保存失败",error!)
        }else{
            print("保存成功")
        }
    }
    
    @IBAction func 打开手电筒(_ sender: UIButton) {
        self.camView.openTorch(self.camView.isTorchActive() ? .off : .on)
        sender.isSelected = !self.camView.isTorchActive()
    }
    
    //切换摄像头
    @IBAction func houAction(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        if sender.isSelected {
            //切换前置摄像头
            self.camView.changeCam(position: .front)
        } else {
            //切换后置摄像头
            self.camView.changeCam(position: .back)
        }
    }
    
    @IBAction func 滤镜点击事件(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        weak var weakSelf = self
        self.collectionViewHeight.constant = sender.isSelected ? 200 : 0
        UIView.animate(withDuration: 0.25) {
            weakSelf?.view.layoutIfNeeded()
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touchuPoint = touches.randomElement()?.location(in: self.view)
        weak var weakSelf = self
        if self.finishedFrame.contains(touchuPoint!) {
            UIView.animate(withDuration: 0.25) {
                weakSelf?.camView.frame = (weakSelf?.startFrame)!
                weakSelf?.camView.layer.cornerRadius = (weakSelf?.startFrame.size.width)!/2;
            }
        }
    }
}

extension ViewController {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.array.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell:FilterCollectionViewCell = collectionView.dequeueReusableCell(withReuseIdentifier: "FilterCollectionViewCell", for: indexPath) as! FilterCollectionViewCell
        let dic = self.array[indexPath.row]
        cell.imageView.image = dic["image"] as? UIImage
        cell.label.text = dic["name"] as? String
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 100, height: self.collectionViewHeight.constant)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 10.0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 10.0, bottom: 0, right: 10.0)
    }
}

