//
//  ViewController.swift
//  Demo_Gcd_download
//
//  Created by Anh vũ on 1/7/21.
//

import UIKit
import ObjectMapper
import Alamofire
import AlamofireObjectMapper
import Photos


class ViewController: UIViewController {
    @IBOutlet weak var downloadLbl: UILabel!
    let queue = DispatchQueue(label: "com.ttc.myqueue", attributes: .concurrent)
    let semaphore = DispatchSemaphore(value: 2)
    let dispathGroup = DispatchGroup()
    var request: DataRequest?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        downloadLbl.isHidden = true
    }
    
    func request(success: @escaping ([DownloadModel]) -> ()) {
        let urlInput = "https://jsonplaceholder.typicode.com/photos"
        request = Alamofire.request(urlInput, method: .get)
        request?.responseArray { (response: DataResponse<[DownloadModel]>) in
            switch response.result {
            case .success:
                DispatchQueue.main.async {
                    success(response.result.value ?? [])
                }
            case .failure(let error):
                print(error.localizedDescription)
            }
        }
    }
    
    @IBAction func pauseAction(_ sender: Any) {
        //        request?.session.invalidateAndCancel()
        
        request?.session.getTasksWithCompletionHandler { (sessionDataTask, uploadData, downloadData) in
            sessionDataTask.forEach { $0.cancel() }
        }
    }
    
    @IBAction func downloadAction(_ sender: Any) {
        self.dispathGroup.enter()
        request { (data) in
            let array = data.prefix(10)
            for item in array {
                self.queue.sync {
                    print("Downloading ")
                    self.semaphore.wait()
                    self.downloadImg(url: item.url)
                    self.semaphore.signal()
                    print("Downloaded ")
                }
            }
            self.dispathGroup.leave()
        }
        
        dispathGroup.notify(queue: .main) {
            print("download success")
            self.downloadLbl.isHidden = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.downloadLbl.isHidden = true
            }
        }
    }
    
    func downloadImg(url: String) {
        request = Alamofire.request(url)
        request?.responseData { (data) in
            guard let data = data.result.value else { return }
            guard let img = UIImage(data: data) else {return}
            try? PHPhotoLibrary.shared().performChangesAndWait {
                PHAssetChangeRequest.creationRequestForAsset(from: img)
            }
        }
    }
    
}

struct DownloadModel: Mappable {
    var url = ""
    init?(map: Map) {}
    
    mutating func mapping(map: Map) {
        url <- map["url"]
    }
    
    
}
