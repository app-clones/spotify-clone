//
//  ProfileViewController.swift
//  spotify
//
//  Created by Zachary Cummins on 7/7/22.
//

import SDWebImage
import UIKit

class ProfileViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    private let tableView: UITableView = {
        let tableView = UITableView()

        tableView.isHidden = true
        tableView.register(UITableViewCell.self,
                           forCellReuseIdentifier: "cell")

        return tableView
    }()

    private var models = [String]()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Profile"

        tableView.delegate = self
        tableView.dataSource = self

        view.addSubview(tableView)
        fetchProfile()
        view.backgroundColor = .systemBackground
    }

    private func fetchProfile() {
        APICaller.shared.getCurrentUserProfile { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case let .success(model):
                    self?.updateUI(with: model)
                case let .failure(error):
                    print(error.localizedDescription)
                    self?.failedToGetProfile()
                }
            }
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.frame = view.bounds
    }

    private func updateUI(with model: UserProfile) {
        tableView.isHidden = false

        // Configure table models
        models.append("Full Name: \(model.display_name)")
        models.append("Email Address: \(model.email)")
        models.append("User ID: \(model.id)")
        models.append("Plan: \(model.product)")

        createTableHeader(with: model.images.first?.url)

        tableView.reloadData()
    }

    private func createTableHeader(with string: String?) {
        guard let urlString = string, let url = URL(string: urlString) else {
            return
        }

        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: view.width, height: view.width / 1.5))

        let imageSize: CGFloat = headerView.height / 2
        let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: imageSize, height: imageSize))
        headerView.addSubview(imageView)

        imageView.center = headerView.center
        imageView.contentMode = .scaleAspectFill
        imageView.sd_setImage(with: url, completed: nil)
        imageView.layer.masksToBounds = true
        imageView.layer.cornerRadius = imageSize / 2

        tableView.tableHeaderView = headerView
    }

    private func failedToGetProfile() {
        let label = UILabel(frame: .zero)

        label.text = "Failed to load profile"
        label.sizeToFit()
        label.textColor = .secondaryLabel

        view.addSubview(label)
        label.center = view.center
    }

    // MARK: - Table View

    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        return models.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)

        cell.textLabel?.text = models[indexPath.row]
        cell.selectionStyle = .none

        return cell
    }
}
