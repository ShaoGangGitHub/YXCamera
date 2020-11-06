# YXCamera
iOS 自定义简单相机，支持摄像头切换，手电筒，滤镜，美颜

SDK调用

    import UIKit
    import YXToolSDK

    class ViewController: UIViewController {

    @IBOutlet weak var imageView1: UIImageView!
    
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
    }
    
    //拍照
    @IBAction func 拍照事件(_ sender: UIButton) {
        weak var weakSelf = self
        self.camView.start { [self] (image) in
            weakSelf?.imageView1.image = image
            UIImageWriteToSavedPhotosAlbum(image, weakSelf, #selector(saveImage(image:didFinishSavingWithError:contextInfo:)), nil)
        }
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
    }
    
    //切换前置摄像头
    @IBAction func qianAction(_ sender: UIButton) {
        self.camView.changeCam(position: .front)
    }
    
    //切换后置摄像头
    @IBAction func houAction(_ sender: UIButton) {
        self.camView.changeCam(position: .back)
    }

    }
