//
//  Toast.swift
//  Toast
//
//  Created by Pascal Braband on 05.04.21.
//

import UIKit

public class Toast: UIView {
    
    public enum LayoutStyle {
        case title, titleAndSubtitle
    }
    
    // MARK: - Static Values
    public static let primaryTextColor: UIColor = .black
    public static let secondaryTextColor: UIColor = UIColor(white: 0.553, alpha: 1.0)
    public static let tertiaryTextColor: UIColor = UIColor(white: 0.757, alpha: 1.0)
    
    
    
    // MARK: - Views
    
    private var titleLabel: UILabel?
    private var subtitleLabel: UILabel?
    private var labelContainer: UIView?
    
    private var accessoryContainer: UIView?
    private var accessoryImageView: UIImageView?
    
    private var bottomConst: NSLayoutConstraint?
    private var topConst: NSLayoutConstraint?
    
    
    
    // MARK: - Detault values
    
    private let defaultBackgroundColor: UIColor = .white
    private let defaultFont: UIFont = UIFont.boldSystemFont(ofSize: UIFont.systemFontSize)
    
    private var hideAfterTimeoutTask: DispatchWorkItem?
    
    
    
    // MARK: - Fixed values
    
    public let animationDuration: TimeInterval = 0.3
    public let animationCurve: CAMediaTimingFunction = CAMediaTimingFunction(controlPoints: 0.14, 0.39, 0.37, 1.0)
    public let minHeight: CGFloat = 55.0
    public let verticalPadding: CGFloat = 10.0
    public let horizontalPadding: CGFloat = 30.0
    
    public let accessorySpace: CGFloat = 50.0
    public let accessorySize: CGFloat = 26.0
    public var accessoryPadding: CGFloat {
        return (self.accessorySpace - self.accessorySize) / 2
    }
    
    
    
    // MARK: - Properties
    
    /**
     Duration of the toasts display time, before hiding again.
     */
    public var showDuration: TimeInterval = 2.0
    
    /**
     The text color of the title label.
     */
    public var titleLabelColor: UIColor? {
        get {
            return titleLabel?.textColor
        }
        set {
            titleLabel?.textColor = newValue
        }
    }
    
    /**
     The text color of the subtitle label.
     */
    public var subtitleLabelColor: UIColor? {
        get {
            return subtitleLabel?.textColor
        }
        set {
            subtitleLabel?.textColor = newValue
        }
    }
    
    /**
     The font of the title label.
     */
    public var titleLabelFont: UIFont? {
        get {
            return titleLabel?.font
        }
        set {
            titleLabel?.font = newValue
        }
    }
    
    /**
     The font of the subtitle label.
     */
    public var subtitleLabelFont: UIFont? {
        get {
            return subtitleLabel?.font
        }
        set {
            subtitleLabel?.font = newValue
        }
    }
    
    /**
     The text of the title label.
     */
    public var titleLabelText: String? {
        get {
            return titleLabel?.text
        }
        set {
            titleLabel?.text = newValue
        }
    }
    
    /**
     The text of the subtitle label.
     */
    public var subtitleLabelText: String? {
        get {
            return subtitleLabel?.text
        }
        set {
            subtitleLabel?.text = newValue
        }
    }
    
    /**
     The handler which gets called, when the show animation for the toast is started.
     */
    public var startShowHandler: (()->())?
    
    /**
     The handler which gets called, after the show animation has finished.
     */
    public var showCompletionHandler: (()->())?
    
    /**
     The handler which gets called, when the hide animation for the toast is started.
     */
    public var startHideHandler: (()->())?
    
    /**
     The handler which gets called, after the hide animation has finished.
     */
    public var hideCompletionHandler: (()->())?
    
    /**
     The toast's layout style
     */
    public var layoutStyle: LayoutStyle = .titleAndSubtitle
    
    /**
     A UIImage to display next to the title (and subtitle). Either `image` or `accessoryView` can be used, not both. The property that is last set will be used.
     */
    private var image: UIImage?
    
    /**
     A custom accessory UIView to display next to the title (and subtitle). Either `image` or `accessoryView` can be used, not both. The property that is last set will be used.
     */
    private var accessoryView: UIView?
    
    
    
    // MARK: - Status
    
    /**
     Indicates whether the show animation is currently running.
     */
    public private(set) var isShowing: Bool = false
    
    /**
     Indicates whether the hide animation is currently running.
     */
    public private(set) var isHiding: Bool = false
    
    /**
     Indicates whether the toast is currently shown (and not animating)
     */
    public private(set) var isShown: Bool = false
    
    
    
    // MARK: - Setup
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup();
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup();
    }
    
    private func setup() {
        self.translatesAutoresizingMaskIntoConstraints = false
        self.backgroundColor = defaultBackgroundColor
        
        // Shadow
        self.layer.shadowOffset = CGSize(width: 0, height: 00)
        self.layer.shadowColor = UIColor.black.cgColor
        self.layer.shadowOpacity = 0.1
        self.layer.shadowRadius = 30
        
        // Title Label
        titleLabel = UILabel(frame: .zero)
        titleLabel?.translatesAutoresizingMaskIntoConstraints = false
        titleLabel?.textColor = Toast.primaryTextColor
        titleLabel?.font = defaultFont
        titleLabel?.textAlignment = .center
        
        // Subtitle Label
        subtitleLabel = UILabel(frame: .zero)
        subtitleLabel?.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel?.textColor = Toast.secondaryTextColor
        subtitleLabel?.font = defaultFont
        subtitleLabel?.textAlignment = .center
        
        // Set minimum height
        self.addConstraint(NSLayoutConstraint(item: self, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: minHeight))
        
        // Add swipe to hide
        let swipeToHide = UISwipeGestureRecognizer(target: self, action: #selector(hide))
        swipeToHide.direction = .up
        self.addGestureRecognizer(swipeToHide)
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        self.layer.cornerRadius = self.bounds.height/2
    }
    
    
    
    // MARK: - Layout
    
    private func layoutViews() {
        // Remove all subviews from toast
        self.subviews.forEach({ $0.removeFromSuperview() })
        
        // Setup labels
        self.labelContainer = UIView()
        self.labelContainer?.translatesAutoresizingMaskIntoConstraints = false
        switch self.layoutStyle {
        case .title:
            self.labelContainer?.addSubview(titleLabel!)
            self.labelContainer?.addConstraints([
                NSLayoutConstraint(item: titleLabel!, attribute: .top, relatedBy: .equal, toItem: self.labelContainer!, attribute: .top, multiplier: 1.0, constant: 0.0),
                NSLayoutConstraint(item: titleLabel!, attribute: .left, relatedBy: .equal, toItem: self.labelContainer!, attribute: .left, multiplier: 1.0, constant: 0.0),
                NSLayoutConstraint(item: titleLabel!, attribute: .right, relatedBy: .equal, toItem: self.labelContainer!, attribute: .right, multiplier: 1.0, constant: 0.0),
                NSLayoutConstraint(item: titleLabel!, attribute: .bottom, relatedBy: .equal, toItem: self.labelContainer!, attribute: .bottom, multiplier: 1.0, constant: 0.0),
            ])
        case .titleAndSubtitle:
            labelContainer?.addSubview(titleLabel!)
            labelContainer?.addSubview(subtitleLabel!)
            self.labelContainer?.addConstraints([
                NSLayoutConstraint(item: titleLabel!, attribute: .top, relatedBy: .equal, toItem: self.labelContainer!, attribute: .top, multiplier: 1.0, constant: 0.0),
                NSLayoutConstraint(item: titleLabel!, attribute: .left, relatedBy: .equal, toItem: self.labelContainer!, attribute: .left, multiplier: 1.0, constant: 0.0),
                NSLayoutConstraint(item: titleLabel!, attribute: .right, relatedBy: .equal, toItem: self.labelContainer!, attribute: .right, multiplier: 1.0, constant: 0.0),
                NSLayoutConstraint(item: subtitleLabel!, attribute: .top, relatedBy: .equal, toItem: titleLabel!, attribute: .bottom, multiplier: 1.0, constant: 0.0),
                NSLayoutConstraint(item: subtitleLabel!, attribute: .left, relatedBy: .equal, toItem: self.labelContainer!, attribute: .left, multiplier: 1.0, constant: 0.0),
                NSLayoutConstraint(item: subtitleLabel!, attribute: .right, relatedBy: .equal, toItem: self.labelContainer!, attribute: .right, multiplier: 1.0, constant: 0.0),
                NSLayoutConstraint(item: subtitleLabel!, attribute: .bottom, relatedBy: .equal, toItem: self.labelContainer!, attribute: .bottom, multiplier: 1.0, constant: 0.0),
            ])
        }
        self.addSubview(labelContainer!)
        
        // Layout for accessory view
        if self.image != nil || self.accessoryView != nil {
            self.accessoryContainer = UIView()
            self.accessoryContainer?.translatesAutoresizingMaskIntoConstraints = false
            
            self.accessoryContainer?.addConstraints([
                NSLayoutConstraint(item: self.accessoryContainer!, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: accessorySize),
                NSLayoutConstraint(item: self.accessoryContainer!, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: accessorySize),
            ])
            
            var accessory: UIView!
            if image != nil {
                accessoryImageView = UIImageView()
                accessoryImageView?.translatesAutoresizingMaskIntoConstraints = false
                accessoryImageView?.image = self.image
                accessory = accessoryImageView
            } else if let accessoryView = self.accessoryView {
                accessoryView.translatesAutoresizingMaskIntoConstraints = false
                accessory = accessoryView
            }
            
            self.accessoryContainer?.addSubview(accessory)
            self.accessoryContainer?.addConstraints([
                NSLayoutConstraint(item: accessory!, attribute: .top, relatedBy: .equal, toItem: self.accessoryContainer!, attribute: .top, multiplier: 1.0, constant: 0.0),
                NSLayoutConstraint(item: accessory!, attribute: .bottom, relatedBy: .equal, toItem: self.accessoryContainer!, attribute: .bottom, multiplier: 1.0, constant: 0.0),
                NSLayoutConstraint(item: accessory!, attribute: .left, relatedBy: .equal, toItem: self.accessoryContainer!, attribute: .left, multiplier: 1.0, constant: 0.0),
                NSLayoutConstraint(item: accessory!, attribute: .right, relatedBy: .equal, toItem: self.accessoryContainer!, attribute: .right, multiplier: 1.0, constant: 0.0),
            ])
            
            self.addSubview(accessoryContainer!)
            
            // Add constrains
            self.addConstraints([
                NSLayoutConstraint(item: accessory!, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 1.0, constant: 0.0),
                NSLayoutConstraint(item: accessory!, attribute: .left, relatedBy: .equal, toItem: self, attribute: .left, multiplier: 1.0, constant: accessoryPadding),
                NSLayoutConstraint(item: labelContainer!, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1.0, constant: verticalPadding),
                NSLayoutConstraint(item: labelContainer!, attribute: .left, relatedBy: .equal, toItem: accessoryContainer, attribute: .right, multiplier: 1.0, constant: accessoryPadding),
                NSLayoutConstraint(item: self, attribute: .right, relatedBy: .equal, toItem: labelContainer!, attribute: .right, multiplier: 1.0, constant: horizontalPadding + 2 * accessoryPadding),
                NSLayoutConstraint(item: self, attribute: .bottom, relatedBy: .equal, toItem: labelContainer!, attribute: .bottom, multiplier: 1.0, constant: verticalPadding),
            ])
        }
        
        // Layout for labels only
        else {
            // Add constraints
            self.addConstraints([
                NSLayoutConstraint(item: labelContainer!, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1.0, constant: verticalPadding),
                NSLayoutConstraint(item: labelContainer!, attribute: .left, relatedBy: .equal, toItem: self, attribute: .left, multiplier: 1.0, constant: horizontalPadding),
                NSLayoutConstraint(item: self, attribute: .right, relatedBy: .equal, toItem: labelContainer!, attribute: .right, multiplier: 1.0, constant: horizontalPadding),
                NSLayoutConstraint(item: self, attribute: .bottom, relatedBy: .equal, toItem: labelContainer!, attribute: .bottom, multiplier: 1.0, constant: verticalPadding),
            ])
        }
    }
    
    
    
    // MARK: - Options
    
    /**
     Sets the text of the title and optionally the subtitle label.
     
     - parameters:
        - title: The text of the title label.
        - subtitle: The text of the subtitle label.
     
     - returns:
     The `Toast` instance.
     */
    public func text(_ title: String, subtitle: String? = nil) -> Toast {
        self.titleLabelText = title
        self.subtitleLabelText = subtitle
        return self
    }
    
    /**
     Sets the font of all labels.
     
     - parameters:
        - font: The font for all labels in the toast.
     
     - returns:
     The `Toast` instance.
     */
    public func font(_ font: UIFont) -> Toast {
        self.titleLabelFont = font
        self.subtitleLabelFont = font
        return self
    }
    
    /**
     Sets the font for the title and the subtitle label.
     
     - parameters:
        - titleLabel: The font for the title label.
        - subtitleLabel: The font for the subtitle label.
     
     - returns:
     The `Toast` instance.
     */
    public func font(titleLabel titleLabelFont: UIFont, subtitleLabel subtitleLabelFont: UIFont) -> Toast {
        self.titleLabelFont = titleLabelFont
        self.subtitleLabelFont = subtitleLabelFont
        return self
    }
    
    /**
     Sets the text color for all labels.
     
     - parameters:
        - textColor: The text color for all labels in the toast.
     
     - returns:
     The `Toast` instance.
     */
    public func textColor(_ textColor: UIColor) -> Toast {
        self.titleLabelColor = textColor
        self.subtitleLabelColor = textColor
        return self
    }
    
    /**
     Sets the text color for the title and the subtitle label.
     
     - parameters:
        - titleLabel: The text color for the title label.
        - subtitleLabel: The text color for the subtitle label.
     
     - returns:
     The `Toast` instance.
     */
    public func textColor(titleLabel titleLabelColor: UIColor, subtitleLabel subtitleLabelColor: UIColor) -> Toast {
        self.titleLabelColor = titleLabelColor
        self.subtitleLabelColor = subtitleLabelColor
        return self
    }
    
    /**
     Sets the background color for the toast.
     
     - parameters:
        - backgroundColor: The background color for the toast.
     
     - returns:
     The `Toast` instance.
     */
    public func color(_ backgroundColor: UIColor) -> Toast{
        self.backgroundColor = backgroundColor
        return self
    }
    
    /**
     Sets the duration for how long the toast is displayed.
     
     - parameters:
        - duration: The duration of display time for the toast.
     
     - returns:
     The `Toast` instance.
     */
    public func duration(_ showDuration: TimeInterval) -> Toast {
        self.showDuration = showDuration
        return self
    }
    
    /**
     Sets the layout style for the toast.
     
     - parameters:
        - layoutStyle: The layout style for the toast.
     
     - returns:
     The `Toast` instance.
     */
    public func layout(_ layoutStyle: LayoutStyle) -> Toast {
        self.layoutStyle = layoutStyle
        return self
    }
    
    /**
     Sets the accessory image for the toast.
     
     - parameters:
        - image: The accessory image for the toast.
     
     Either `image` or `accessoryView` can be used, not both. The property that is last set will be used.
     
     - returns:
     The `Toast` instance.
     */
    public func image(_ image: UIImage) -> Toast {
        self.accessoryView = nil
        self.image = image
        return self
    }
    
    /**
     Sets the accessory view for the toast.
     
     - parameters:
        - accessoryView: The accessory view for the toast.
     
     Either `image` or `accessoryView` can be used, not both. The property that is last set will be used.
     
     - returns:
     The `Toast` instance.
     */
    public func accessoryView(_ accessoryView: UIView) -> Toast {
        self.image = nil
        self.accessoryView = accessoryView
        return self
    }
    
    /**
     Sets the handler that gets called, when the show animation is started.
     
     - parameters:
        - handler: The handler to be called, when the described action occurs.
     
     - returns:
     The `Toast` instance.
     */
    public func addHandler(startShow handler: (()->())?) -> Toast {
        self.startShowHandler = handler
        return self
    }
    
    /**
     Sets the handler that gets called, when the show animation has finished.
     
     - parameters:
        - handler: The handler to be called, when the described action occurs.
     
     - returns:
     The `Toast` instance.
     */
    public func addHandler(showCompletion handler: (()->())?) -> Toast {
        self.showCompletionHandler = handler
        return self
    }
    
    /**
     Sets the handler that gets called, when the hide animation is started.
     
     - parameters:
        - handler: The handler to be called, when the described action occurs.
     
     - returns:
     The `Toast` instance.
     */
    public func addHandler(startHide handler: (()->())?) -> Toast {
        self.startHideHandler = handler
        return self
    }
    
    /**
     Sets the handler that gets called, when the hide animation has finished.
     
     - parameters:
        - handler: The handler to be called, when the described action occurs.
     
     - returns:
     The `Toast` instance.
     */
    public func addHandler(hideCompletion handler: (()->())?) -> Toast {
        self.hideCompletionHandler = handler
        return self
    }
    
    
    
    // MARK: - Show
    
    /**
     Displays the `Toast` instance in the given `UIViewController`.
     */
    public func show(in viewController: UIViewController) {
        self.show(in: viewController.view)
    }

    /**
     Displays the `Toast` instance in the given `UIView`.
     */
    public func show(in view: UIView) {
        // Only continue if toast is hidden
        guard !isShown else { return }
        
        // Layout views
        layoutViews()
        
        // Show in view
        view.addSubview(self)
        bottomConst = NSLayoutConstraint(item: self, attribute: .bottom, relatedBy: .equal, toItem: view, attribute: .top, multiplier: 1.0, constant: 20.0)
        topConst = NSLayoutConstraint(item: self, attribute: .top, relatedBy: .equal, toItem: view, attribute: .top, multiplier: 1.0, constant: 50.0)
        view.addConstraints([
            NSLayoutConstraint(item: self, attribute: .centerX, relatedBy: .equal, toItem: view, attribute: .centerX, multiplier: 1.0, constant: 0.0),
            bottomConst!
        ])
        view.layoutIfNeeded()
        
        // Update status
        self.startShowHandler?()
        self.isShowing = true
        
        CATransaction.begin()
        CATransaction.setAnimationTimingFunction(animationCurve)

        UIView.animate(withDuration: animationDuration) {
            // Change toast position
            self.bottomConst?.isActive = false
            self.topConst?.isActive = true
            view.layoutIfNeeded()
        } completion: { (success) in
            // Update status
            self.isShowing = false
            self.isShown = true
            
            // Call completion handler
            self.showCompletionHandler?()
            
            // Initiate hide animation
            self.hideAfterTimeoutTask = DispatchWorkItem {
                self.hide()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + self.showDuration, execute: self.hideAfterTimeoutTask!)
        }

        CATransaction.commit()
    }
    
    /**
     Hides the toast.
     */
    @objc
    public func hide() {
        // Only continue if toast is shown
        guard isShown else { return }
        
        // Cancel hide task if still running
        self.hideAfterTimeoutTask?.cancel()
        
        // Update Status
        self.startHideHandler?()
        self.isHiding = true
        
        CATransaction.begin()
        CATransaction.setAnimationTimingFunction(animationCurve)

        UIView.animate(withDuration: animationDuration) {
            // Change toast position
            self.topConst?.isActive = false
            self.bottomConst?.isActive = true
            self.superview?.layoutIfNeeded()
        } completion: { (success) in
            // Update status
            self.isHiding = false
            self.isShown = false
            
            self.removeFromSuperview()
            
            // Call completion handler
            self.hideCompletionHandler?()
        }

        CATransaction.commit()
    }
    
}
