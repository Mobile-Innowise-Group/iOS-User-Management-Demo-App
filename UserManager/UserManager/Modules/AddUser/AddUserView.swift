import UIKit
import Combine

final class AddUserViewController: UIViewController {
    private var cancellables = Set<AnyCancellable>()
    private let viewModel: AddUserViewModel
    
    private let defaultSpacing = AppConstants.AddUser.ViewConstraint.defaultSpacing.rawValue
    private let defaultHeight = AppConstants.AddUser.ViewConstraint.defaultHeight.rawValue

    init(viewModel: AddUserViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("\(Self.self).init(coder:) has not been implemented")
    }

    private lazy var stackView: UIStackView = {
        let view = UIStackView()
        view.axis = .vertical
        view.spacing = defaultSpacing / 8.0
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var nameTextField: UITextField = {
        let textField = UITextField()
        textField.textContentType = .name
        textField.keyboardType = .namePhonePad
        textField.autocorrectionType = .no
        textField.autocapitalizationType = .none
        textField.borderStyle = .roundedRect
        textField.placeholder = AppConstants.AddUser.Title.name.rawValue
        return textField
    }()

    private lazy var emailTextField: UITextField = {
        let textField = UITextField()
        textField.textContentType = .emailAddress
        textField.keyboardType = .emailAddress
        textField.autocorrectionType = .no
        textField.autocapitalizationType = .none
        textField.borderStyle = .roundedRect
        textField.placeholder = AppConstants.AddUser.Title.email.rawValue
        return textField
    }()

    private lazy var submitButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle(AppConstants.AddUser.Title.submit.rawValue, for: .normal)
        button.setTitleColor(.lightGray, for: .disabled)
        button.addTarget(self, action: #selector(onSubmit), for: .touchUpInside)
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupViews()
        setupConstraints()
        setupPublishers()
    }

    private func setupViews() {
        view.addSubview(stackView)
        stackView.addArrangedSubview(nameTextField)
        stackView.addArrangedSubview(emailTextField)
        stackView.addArrangedSubview(submitButton)
        navigationItem.title = AppConstants.AddUser.Title.navItem.rawValue
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: defaultSpacing),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -defaultSpacing),
            nameTextField.heightAnchor.constraint(equalToConstant: defaultHeight),
            emailTextField.heightAnchor.constraint(equalToConstant: defaultHeight),
            submitButton.heightAnchor.constraint(equalToConstant: defaultHeight)
        ])
    }

    private func setupPublishers() {
        NotificationCenter.default
            .publisher(for: UITextField.textDidChangeNotification, object: nameTextField)
            .compactMap { ($0.object as? UITextField)?.text }
            .assign(to: \.name, on: viewModel)
            .store(in: &cancellables)
        NotificationCenter.default
            .publisher(for: UITextField.textDidChangeNotification, object: emailTextField)
            .compactMap { ($0.object as? UITextField)?.text }
            .assign(to: \.email, on: viewModel)
            .store(in: &cancellables)

        viewModel.isSubmitEnabled
            .assign(to: \.isEnabled, on: submitButton)
            .store(in: &cancellables)

        viewModel.$state
            .sink { [weak self] state in
                switch state {
                case .loading:
                    self?.submitButton.isEnabled = false
                    self?.submitButton.setTitle(AppConstants.AddUser.Message.loading.rawValue, for: .normal)
                case .success:
                    self?.resetButton()
                    SimpleMessage.displayComfiguredWithTheme(
                        .success, 
                        withTitle: AppConstants.AddUser.Message.done.rawValue,
                        withBody: AppConstants.AddUser.Message.saved.rawValue
                    )
                    self?.navigationController?.popViewController(animated: true)
                case .failed:
                    self?.resetButton()
                    SimpleMessage.displayComfiguredWithTheme(
                        .failure, 
                        withTitle: AppConstants.AddUser.Message.error.rawValue,
                        withBody: AppConstants.AddUser.Message.alreadyExists.rawValue
                    )
                case .none:
                    break
                }
            }
            .store(in: &cancellables)
    }

    @objc private func onSubmit() {
        viewModel.submit()
    }

    private func resetButton() {
        submitButton.setTitle(AppConstants.AddUser.Title.submit.rawValue, for: .normal)
        submitButton.isEnabled = true
    }
}