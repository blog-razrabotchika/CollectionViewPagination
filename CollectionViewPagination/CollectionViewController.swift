import UIKit
import NHBalancedFlowLayout

private let reuseIdentifier = "Cell"

class CollectionViewController: UICollectionViewController, NHBalancedFlowLayoutDelegate {
    
    var photosLinks = [String]()
    var photosArray = [UIImage]()
    
    var offset = 15
    var position = 0
    
    var spinner = UIActivityIndicatorView()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupCollection()
        setupNavBar()
        addSpinner()

        loadAPIData()
    }
    
    @objc func loadAPIData() {
        if !self.photosLinks.isEmpty {
            self.photosLinks.removeAll()
            self.photosArray.removeAll()
            offset = 15
            position = 0
            self.collectionView.reloadData()
        }
        
        loadData { [weak self] (imageUrls) in
            guard let self = self else { return }
                   self.photosLinks = imageUrls
                   self.recountOffset()
                   self.downloadAllImages()
        }
    }
    
    func setupNavBar() {
        self.title = "CollectionViewPagination"
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(loadAPIData))

    }
    
    func recountOffset() {
        if (self.photosLinks.count <= offset - 1) {
            offset = photosLinks.count
            print("Offset: \(offset)")
        }
    }
    
    func collectionView(_ collectionView: UICollectionView!, layout collectionViewLayout: NHBalancedFlowLayout!, preferredSizeForItemAt indexPath: IndexPath!) -> CGSize {
        let size = photosArray[indexPath.item].size
        return size
    }
    
    func setupCollection() {
        self.collectionView.collectionViewLayout = NHBalancedFlowLayout()
        self.collectionView?.register(AlbumCell.self, forCellWithReuseIdentifier: reuseIdentifier)
        self.collectionView?.delegate = self
        self.collectionView?.dataSource = self
    }
    
    func startSpinner() {
        if !spinner.isAnimating {
            spinner.startAnimating()
        }
    }
    
    
    func addSpinner() {
        self.view.addSubview(spinner)
            spinner.center = self.view.center
            spinner.style = .large
            spinner.color = .white
    }
    
    override func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        
        if (indexPath.item == self.photosArray.count - 5)  {
            
            startSpinner()
            
                if (self.photosArray.count < self.photosLinks.count) {
                        loadImages(pos: position, off: offset) { [weak self] (completion) in
                            guard let self = self else { return }
                            self.photosArray.append(contentsOf: completion)
                                                                        
                            do {
                                self.countIndexPathsAndUpdate()
                            }
                        }
                }
            }
    }
    
    func downloadAllImages() {
          self.loadImages(pos: self.position, off: self.offset) { [weak self] (completion) in
            guard let self = self else { return }
            self.photosArray.append(contentsOf: completion)
            self.countIndexPathsAndUpdate()
        }
    }
    
    func loadData(completion: @escaping ([String]) -> Void) {
        startSpinner()
        
        let url = URL(string: "https://picsum.photos/v2/list?page=1&limit=100")
        
        let sessionConfig = URLSessionConfiguration.default

        let session = URLSession(configuration: sessionConfig, delegate: nil, delegateQueue: nil)

        guard let URL = url else { return }
        let request = URLRequest(url: URL)
        

        let task = session.dataTask(with: request) { (data, response, err) in
            if (err == nil) {
                if let data = data {
                    
                    do {
                        let jsonResult = try JSONSerialization.jsonObject(with: data, options: .mutableContainers)

                        if let json = jsonResult as? [[String: Any]] {
                        
                            var imagesUrls = [String]()

                            for image in json {
                                guard let dUrl = image["download_url"] as? String else { return }
                                imagesUrls.append(dUrl)
                            }
                            
                            if imagesUrls.count == 100 {
                                completion(imagesUrls)
                            }
                        } else {
                            print("JSON ERROR")
                            return
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
                if photosLinks.indices.contains(i) {
                    ImageLoader.sharedLoader.imageForUrl(urlString: photosLinks[i], completionHandler:{(image: UIImage?, url: String) in
                            guard let im = image else { return }
                                images.append(im)
                                if i + 1 == pos + off {
                                    completion(images)
                                    return
                                }
                    })
                }
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
