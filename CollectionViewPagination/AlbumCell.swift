import UIKit

class AlbumCell: UICollectionViewCell {
    
      let imageView : UIImageView = {
            let iv = UIImageView()
            iv.translatesAutoresizingMaskIntoConstraints = false
            iv.contentMode = .scaleToFill
            iv.clipsToBounds = true
            return iv
        }()
        
        override init(frame: CGRect) {
            super.init(frame: .zero)
            self.backgroundColor = .white
            self.addSubview(imageView)
        }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let constraints = [
                  imageView.topAnchor.constraint(equalTo: self.topAnchor),
                  imageView.leftAnchor.constraint(equalTo: self.leftAnchor),
                  imageView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
                  imageView.rightAnchor.constraint(equalTo: self.rightAnchor)
                  ]
                                
                  NSLayoutConstraint.activate(constraints)
    }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

    
}
