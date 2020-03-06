import UIKit
import NHBalancedFlowLayout

private let reuseIdentifier = "Cell"

class CollectionViewController: UICollectionViewController, NHBalancedFlowLayoutDelegate {
    
    var photosLinks = [String]()
    var photosArray = [UIImage]()
    
    var offset = 15
    var position = 0
    
    var spinner = UIActivityIndicatorView()
    
    func collectionView(_ collectionView: UICollectionView!, layout collectionViewLayout: NHBalancedFlowLayout!, preferredSizeForItemAt indexPath: IndexPath!) -> CGSize {
        let size = photosArray[indexPath.item].size
        return size
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.collectionView!.register(AlbumCell.self, forCellWithReuseIdentifier: reuseIdentifier)
        self.collectionView?.delegate = self
        self.collectionView?.dataSource = self
        
        self.view.addSubview(spinner)
        spinner.center = self.view.center
        spinner.style = .large
        spinner.startAnimating()
        
        loadData { (imageUrls) in
            self.photosLinks = imageUrls
            print(self.photosLinks)
            self.downloadAllImages()
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        
        if (indexPath.item == self.photosArray.count - 5)  {
            
            if !spinner.isAnimating {
                spinner.startAnimating()
            }
            
                if (self.photosArray.count < self.photosLinks.count) {
                        loadImages(pos: position, off: offset) { (completion) in
                                               
                        self.photosArray.append(contentsOf: completion)
                            
                        print("links: \(self.photosLinks.count) || Photos: \(self.photosArray.count)")
                                               
                            do {
                                self.countIndexPathsAndUpdate()
                            }
                        }
                }
            }
    }
    
    func downloadAllImages() {
          self.loadImages(pos: self.position, off: self.offset) { (completion) in
            self.photosArray.append(contentsOf: completion)
            self.countIndexPathsAndUpdate()
        }
    }
    
    func loadData(completion: @escaping ([String]) -> Void) {
        let url = URL(string: "https://picsum.photos/v2/list?page=1&limit=100")
        
        let sessionConfig = URLSessionConfiguration.default

        let session = URLSession(configuration: sessionConfig, delegate: nil, delegateQueue: nil)

        guard let URL = url else { return }
        let request = URLRequest(url: URL)
        

        let task = session.dataTask(with: request) { (data, response, err) in
            if (err == nil) {
                let statusCode = (response as! HTTPURLResponse).statusCode
                print("URL Session Task Succeeded: HTTP \(statusCode)")
                if let data = data {
                    
                    do {
                        let jsonResult = try JSONSerialization.jsonObject(with: data, options: .mutableContainers)

                        let json = jsonResult as? [[String: Any]]
                        
                        var imagesUrls = [String]()

                        for image in json! {
                            imagesUrls.append(image["download_url"] as! String)
                        }
                        
                        if imagesUrls.count == 100 {
                            completion(imagesUrls)
                        }
                        
                    } catch let err {
                        print(err)
                    }

                }
            } else {
                print("URL Session Task Failed: \(err!.localizedDescription)")
            }
        }
        task.resume()
        session.finishTasksAndInvalidate()
    }
    
    func loadImages(pos: Int, off: Int, completion:  @escaping ([UIImage]) -> Void) {
           var images = [UIImage]()
     
           for i in pos..<pos+off {
                   self.loadImageFromUrl(urlString: photosLinks[i]) { (image) in
                       images.append(image)
                       if i + 1 == pos + off {
                           completion(images)
                           return
                       }
                   }
           }
       }

 func loadImageFromUrl(urlString: String, completion: @escaping (UIImage) -> Void) {
        
        let url = URL(string: urlString) ?? URL(string: "https://miro.medium.com/max/978/1*pUEZd8z__1p-7ICIO1NZFA.png")!
        
        
        var image = UIImage()
        let cache = URLCache.shared
        let urlRequest = URLRequest(url: url)
        
        if let data = cache.cachedResponse(for: urlRequest)?.data, let cachedImage = UIImage(data: data) {
            DispatchQueue.main.async {
                print("From Cache")
                completion(cachedImage)
            }
        } else {
            let task = URLSession.shared.dataTask(with: urlRequest) { (data, response, error) in
                guard let unwrappedData = data else { return }
                do {
                    DispatchQueue.main.async {
                        image = UIImage(data: unwrappedData) ?? UIImage(named: "logo")!
                        completion(image)
                    }
                }
            }
            task.resume()
        }
    }
    
    func countIndexPathsAndUpdate() {
         var i = self.position
         var array = [IndexPath]()
         
         while i < self.position+self.offset {
             let indexPath = IndexPath.init(item: i, section: 0)
             if (self.photosArray.indices.contains(i)) {
                 array.append(indexPath)
             }
             
             i += 1
             
             if i == self.position + self.offset {
                 DispatchQueue.main.async {
                     self.collectionView?.insertItems(at: array)
                     self.position = self.photosArray.count
                     if (self.photosArray.count + self.offset > self.photosLinks.count ||
                         self.photosArray.count + self.offset == self.photosLinks.count) {
                         self.offset = self.photosLinks.count - self.photosArray.count
                     }
                    self.spinner.stopAnimating()
                 }
                 break
             }
         }
                               
         
     }


    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return photosArray.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! AlbumCell
        
        cell.imageView.image = photosArray[indexPath.item]
     
        return cell
    }
    
}
