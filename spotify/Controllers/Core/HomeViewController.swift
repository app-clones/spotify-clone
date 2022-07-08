//
//  ViewController.swift
//  spotify
//
//  Created by Zachary Cummins on 7/7/22.
//

import UIKit

class HomeViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Browse"
        view.backgroundColor = .systemBackground

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "gear"),
            style: .done,
            target: self,
            action: #selector(didTapSettings)
        )

        fetchData()
    }

    // MARK: - Private Functions

    private func fetchData() {
        APICaller.shared.getRecommendedGenres { result in
            switch result {
            case let .success(model):
                let genres = model.genres

                var seeds = Set<String>()
                while seeds.count < 5 {
                    if let random = genres.randomElement() {
                        seeds.insert(random)
                    }
                }

                APICaller.shared.getRecommendations(genres: seeds) { result in
                    switch result {
                    case let .success(model):
                        print(model)
                    case let .failure(error):
                        print(error)
                    }
                }
            case let .failure(error):
                print(error)
            }
        }
    }

    @objc func didTapSettings() {
        let vc = SettingsViewController()

        vc.title = "Settings"
        vc.navigationItem.largeTitleDisplayMode = .never

        navigationController?.pushViewController(vc, animated: true)
    }
}
