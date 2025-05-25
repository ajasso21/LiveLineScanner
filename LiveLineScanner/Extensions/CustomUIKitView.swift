import UIKit

/// A simple UIKit view that draws a colored circle.
class CustomUIKitView: UIView {
    // MARK: - Outlets
    @IBOutlet private var contentView: UIView!
    
    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupFromNib()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupFromNib()
    }
    
    private func setupFromNib() {
        Bundle.main.loadNibNamed("CustomUIKitView", owner: self)
        addSubview(contentView)
        contentView.frame = bounds
        contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        backgroundColor = .clear
    }
    
    override func draw(_ rect: CGRect) {
        // Draw a red circle filling the view
        if let ctx = UIGraphicsGetCurrentContext() {
            ctx.setFillColor(UIColor.systemRed.cgColor)
            ctx.fillEllipse(in: rect.insetBy(dx: 10, dy: 10))
        }
    }
}
