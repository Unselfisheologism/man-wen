import UIKit

class BlockingViewController: UIViewController {

    private let confidence: Float
    private let className: String
    private var dismissTimer: Timer?

    init(confidence: Float, className: String) {
        self.confidence = confidence
        self.className = className
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
        view.backgroundColor = UIColor.black.withAlphaComponent(0.9)

        let blur = UIBlurEffect(style: .dark)
        let blurView = UIVisualEffectView(effect: blur)
        blurView.frame = view.bounds
        blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(blurView)

        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 24
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stack.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 40),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -40)
        ])

        let icon = UILabel()
        icon.text = "🛡️"
        icon.font = .systemFont(size: 72)

        let message = UILabel()
        message.text = confidence > 0.9
            ? "⚠️ Inappropriate Content Blocked\n(\(String(format: "%.0f%%", confidence * 100)))"
            : "⚠️ Potentially Inappropriate\n(\(String(format: "%.0f%%", confidence * 100)))"
        message.textColor = .white
        message.font = .boldSystemFont(ofSize: 22)
        message.numberOfLines = 0
        message.textAlignment = .center

        let dismiss = UILabel()
        dismiss.text = "Tap to dismiss"
        dismiss.textColor = UIColor.white.withAlphaComponent(0.6)
        dismiss.font = .systemFont(ofSize: 14)

        stack.addArrangedSubview(icon)
        stack.addArrangedSubview(message)
        stack.addArrangedSubview(dismiss)

        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissTapped))
        view.addGestureRecognizer(tap)

        dismissTimer?.invalidate()
        dismissTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { [weak self] _ in
            self?.dismiss(animated: true)
        }
    }

    @objc private func dismissTapped() {
        dismiss(animated: true)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        dismissTimer?.invalidate()
    }
}