//
//  ViewController.swift
//  spotify
//
//  Created by Zachary Cummins on 7/7/22.
//

import UIKit

enum BrowseSectionType {
    case newReleases(viewModels: [NewReleasesCellViewModel]) // 1
    case featuredPlaylists(viewModels: [FeaturedPlaylistCellViewModel]) // 2
    case recommendedTracks(viewModels: [RecommendedTrackCellViewModel]) // 3
}

class HomeViewController: UIViewController {
    // MARK: - Private Variables

    private var collectionView: UICollectionView = .init(
        frame: .zero,
        collectionViewLayout: UICollectionViewCompositionalLayout { sectionIndex, _ in
            HomeViewController.createSectionLayout(section: sectionIndex)
        }
    )

    private let spinner: UIActivityIndicatorView = {
        let spinner = UIActivityIndicatorView()

        spinner.tintColor = .label
        spinner.hidesWhenStopped = true

        return spinner
    }()

    private var sections = [BrowseSectionType]()

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

        configureCollectionView()
        fetchData()

        view.addSubview(spinner)
    }

    // MARK: - Private Functions

    private func configureCollectionView() {
        view.addSubview(collectionView)

        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "cell")

        collectionView.register(
            NewReleaseCollectionViewCell.self,
            forCellWithReuseIdentifier: NewReleaseCollectionViewCell.identifier
        )
        collectionView.register(
            FeaturedPlaylistCollectionViewCell.self,
            forCellWithReuseIdentifier: FeaturedPlaylistCollectionViewCell.identifier
        )
        collectionView.register(
            RecommendedTrackCollectionViewCell.self,
            forCellWithReuseIdentifier: RecommendedTrackCollectionViewCell.identifier
        )

        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.backgroundColor = .systemBackground
    }

    private func fetchData() {
        let group = DispatchGroup()

        group.enter()
        group.enter()
        group.enter()

        var newReleases: NewReleasesResponse?
        var featuredPlaylist: FeaturedPlaylistsResponse?
        var recommendations: RecommendationsResponse?

        // New Releases
        APICaller.shared.getNewReleases { result in

            defer {
                group.leave()
            }

            switch result {
            case let .success(model):
                newReleases = model
            case let .failure(error):
                print(error.localizedDescription)
            }
        }

        // Featured playlists
        APICaller.shared.getFeaturedPlaylists { result in
            defer {
                group.leave()
            }

            switch result {
            case let .success(model):
                featuredPlaylist = model
            case let .failure(error):
                print(error.localizedDescription)
            }
        }

        // Recommended Tracks
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

                APICaller.shared.getRecommendations(genres: seeds) { recommendedResults in
                    defer {
                        group.leave()
                    }

                    switch recommendedResults {
                    case let .success(model):
                        recommendations = model
                    case let .failure(error):
                        print(error.localizedDescription)
                    }
                }
            case let .failure(error):
                print(error.localizedDescription)
            }
        }

        group.notify(queue: .main) {
            guard let newAlbums = newReleases?.albums.items,
                  let playlists = featuredPlaylist?.playlists.items,
                  let tracks = recommendations?.tracks
            else {
                fatalError("Models are nil")
            }

            self.configureModels(newAlbums: newAlbums, playlists: playlists, tracks: tracks)
        }
    }

    private func configureModels(
        newAlbums: [Album],
        playlists: [Playlist],
        tracks: [AudioTrack]
    ) {
        sections.append(.newReleases(viewModels: newAlbums.compactMap {
            NewReleasesCellViewModel(
                name: $0.name,
                artworkURL: URL(string: $0.images.first?.url ?? ""),
                numberofTracks: $0.total_tracks,
                artistName: $0.artists.first?.name ?? "-"
            )
        }))

        sections.append(.featuredPlaylists(viewModels: playlists.compactMap {
            FeaturedPlaylistCellViewModel(
                name: $0.name,
                artworkUrl: URL(string: $0.images.first?.url ?? ""),
                creatorName: $0.owner.display_name
            )
        }))

        sections.append(.recommendedTracks(viewModels: tracks.compactMap {
            RecommendedTrackCellViewModel(
                name: $0.name,
                artistName: $0.artists.first?.name ?? "-",
                artworkUrl: URL(string: $0.album.images.first?.url ?? "")
            )
        }))

        collectionView.reloadData()
    }

    @objc func didTapSettings() {
        let vc = SettingsViewController()

        vc.title = "Settings"
        vc.navigationItem.largeTitleDisplayMode = .never

        navigationController?.pushViewController(vc, animated: true)
    }

    // MARK: - Overrides

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        collectionView.frame = view.bounds
    }
}

extension HomeViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let type = sections[section]

        switch type {
        case let .newReleases(viewModels):
            return viewModels.count
        case let .featuredPlaylists(viewModels):
            return viewModels.count
        case let .recommendedTracks(viewModels):
            return viewModels.count
        }
    }

    func numberOfSections(in _: UICollectionView) -> Int {
        return sections.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let type = sections[indexPath.section]

        switch type {
        case let .newReleases(viewModels):
            guard let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: NewReleaseCollectionViewCell.identifier,
                for: indexPath
            ) as? NewReleaseCollectionViewCell else {
                return UICollectionViewCell()
            }

            let viewModel = viewModels[indexPath.row]

            cell.configure(with: viewModel)

            return cell
        case let .featuredPlaylists(viewModels):
            guard let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: FeaturedPlaylistCollectionViewCell.identifier,
                for: indexPath
            ) as? FeaturedPlaylistCollectionViewCell else {
                return UICollectionViewCell()
            }

            cell.configure(with: viewModels[indexPath.row])

            return cell
        case let .recommendedTracks(viewModels):
            guard let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: RecommendedTrackCollectionViewCell.identifier,
                for: indexPath
            ) as? RecommendedTrackCollectionViewCell else {
                return UICollectionViewCell()
            }

            cell.configure(with: viewModels[indexPath.row])

            return cell
        }
    }

    static func createSectionLayout(section: Int) -> NSCollectionLayoutSection {
        switch section {
        // New Releases
        case 0:
            // Item
            let item = NSCollectionLayoutItem(
                layoutSize: NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: .fractionalHeight(1.0)
                )
            )

            item.contentInsets = NSDirectionalEdgeInsets(top: 2, leading: 2, bottom: 2, trailing: 2)

            // Vertical group in horizontal group
            let verticalGroup = NSCollectionLayoutGroup.vertical(
                layoutSize: NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: .absolute(390)
                ),
                subitem: item,
                count: 3
            )

            let horizontalGroup = NSCollectionLayoutGroup.horizontal(
                layoutSize: NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(0.9),
                    heightDimension: .absolute(390)
                ),
                subitem: verticalGroup,
                count: 1
            )

            // Section
            let section = NSCollectionLayoutSection(group: horizontalGroup)
            section.orthogonalScrollingBehavior = .groupPaging

            return section

        // Featured Playlists
        case 1:
            // Item
            let item = NSCollectionLayoutItem(
                layoutSize: NSCollectionLayoutSize(
                    widthDimension: .absolute(200),
                    heightDimension: .absolute(200)
                )
            )

            item.contentInsets = NSDirectionalEdgeInsets(top: 2, leading: 2, bottom: 2, trailing: 2)

            let verticalGroup = NSCollectionLayoutGroup.vertical(
                layoutSize: NSCollectionLayoutSize(
                    widthDimension: .absolute(200),
                    heightDimension: .absolute(400)
                ),
                subitem: item,
                count: 2
            )

            let horizontalGroup = NSCollectionLayoutGroup.horizontal(
                layoutSize: NSCollectionLayoutSize(
                    widthDimension: .absolute(200),
                    heightDimension: .absolute(400)
                ),
                subitem: verticalGroup,
                count: 1
            )

            // Section
            let section = NSCollectionLayoutSection(group: horizontalGroup)
            section.orthogonalScrollingBehavior = .continuous

            return section

        // Recommended Tracks
        case 2:
            // Item
            let item = NSCollectionLayoutItem(
                layoutSize: NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: .fractionalHeight(1.0)
                )
            )

            item.contentInsets = NSDirectionalEdgeInsets(top: 2, leading: 2, bottom: 2, trailing: 2)

            let group = NSCollectionLayoutGroup.vertical(
                layoutSize: NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1),
                    heightDimension: .absolute(80)
                ),
                subitem: item,
                count: 1
            )

            // Section
            let section = NSCollectionLayoutSection(group: group)

            return section
        default:
            // Item
            let item = NSCollectionLayoutItem(
                layoutSize: NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: .fractionalHeight(1.0)
                )
            )

            item.contentInsets = NSDirectionalEdgeInsets(top: 2, leading: 2, bottom: 2, trailing: 2)

            // Vertical group in horizontal group
            let group = NSCollectionLayoutGroup.vertical(
                layoutSize: NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: .absolute(390)
                ),
                subitem: item,
                count: 1
            )

            // Section
            let section = NSCollectionLayoutSection(group: group)

            return section
        }
    }
}
