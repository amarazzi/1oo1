import SwiftUI

struct PopoverRootView: View {
    @Environment(\.appEnvironment) private var env
    @State private var showMovieRating = false
    @State private var showAlbumRating = false
    @State private var screen: Screen = .main

    enum Screen { case main, history, settings }

    var vm: AppViewModel { env.viewModel }

    var body: some View {
        VStack(spacing: 0) {
            switch screen {
            case .main:
                mainContent
            case .history:
                subScreen(title: "History") { HistoryView() }
            case .settings:
                subScreen(title: "Settings") {
                    SettingsView(onHistory: { screen = .history })
                }
            }
        }
        .frame(width: 360)
        // Movie rating sheet
        .sheet(isPresented: $showMovieRating) {
            if let movie = vm.currentMovie {
                MovieRatingModal(movie: movie) { rating, notes in
                    Task { await vm.markMovieWatched(rating: rating, notes: notes) }
                } onSkip: {
                    Task { await vm.markMovieWatched(rating: nil, notes: nil) }
                }
            }
        }
        // Album rating sheet
        .sheet(isPresented: $showAlbumRating) {
            if let album = vm.currentAlbum {
                AlbumRatingModal(album: album) { rating, notes in
                    Task { await vm.markAlbumListened(rating: rating, notes: notes) }
                } onSkip: {
                    Task { await vm.markAlbumListened(rating: nil, notes: nil) }
                }
            }
        }
    }

    // MARK: - Main screen

    @ViewBuilder
    private var mainContent: some View {
        VStack(spacing: 10) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 1) {
                    Text("1001")
                        .font(.system(size: 22, weight: .black, design: .rounded))
                        .foregroundStyle(.primary)
                    Text("movies & albums")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.secondary)
                        .tracking(1.5)
                        .textCase(.uppercase)
                }
                Spacer()
                Button {
                    Task { await vm.refreshRecommendations() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help("Refresh")
            }
            .padding(.horizontal, 14)
            .padding(.top, 10)
            .padding(.bottom, 2)

            Divider().padding(.horizontal, 10)

            // Movie section
            if vm.allMoviesCompleted {
                MovieCompletedView()
            } else if let movie = vm.currentMovie {
                MovieCardView(
                    movie: movie,
                    image: vm.moviePosterImage,
                    isLoading: vm.isLoadingMovie,
                    onWatched: { showMovieRating = true },
                    onSkip: { Task { await vm.skipMovie() } }
                )
            } else if vm.isLoadingMovie {
                loadingCard(label: "Loading movie...")
            } else if let err = vm.movieError {
                errorCard(label: err)
            }

            // Album section
            if vm.allAlbumsCompleted {
                AlbumCompletedView()
            } else if let album = vm.currentAlbum {
                AlbumCardView(
                    album: album,
                    image: vm.albumCoverImage,
                    isLoading: vm.isLoadingAlbum,
                    onListened: { showAlbumRating = true },
                    onSkip: { Task { await vm.skipAlbum() } }
                )
            } else if vm.isLoadingAlbum {
                loadingCard(label: "Loading album...")
            } else if let err = vm.albumError {
                errorCard(label: err)
            }

            // Footer
            Divider().padding(.horizontal, 10)

            HStack {
                Button { screen = .history } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "clock.arrow.circlepath").font(.caption)
                        HStack(spacing: 4) {
                            Image(systemName: "film.stack").font(.caption2).foregroundStyle(.indigo)
                            Text("\(vm.movieCompletedCount)").font(.caption.monospacedDigit()).foregroundStyle(.secondary)
                            Text("·").foregroundStyle(.tertiary)
                            Image(systemName: "music.note.list").font(.caption2).foregroundStyle(.purple)
                            Text("\(vm.albumCompletedCount)").font(.caption.monospacedDigit()).foregroundStyle(.secondary)
                        }
                    }
                    .foregroundStyle(.primary)
                }
                .buttonStyle(.plain)

                Spacer()

                Button { screen = .settings } label: {
                    Image(systemName: "gearshape").font(.caption).foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 10)
        }
        .padding(.horizontal, 10)
        .padding(.top, 6)
    }

    // MARK: - Sub-screen wrapper

    @ViewBuilder
    private func subScreen<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 0) {
            // Navigation bar
            HStack(spacing: 8) {
                Button { screen = .main } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.primary)
                        .frame(width: 28, height: 28)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                Text(title)
                    .font(.headline)

                Spacer()
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)

            Divider()

            content()
                .frame(height: 420)
        }
    }

    // MARK: - Helpers

    @ViewBuilder
    private func loadingCard(label: String) -> some View {
        HStack(spacing: 10) {
            ProgressView().scaleEffect(0.8)
            Text(label).font(.subheadline).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(.background.secondary)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    @ViewBuilder
    private func errorCard(label: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "wifi.slash").foregroundStyle(.orange)
            Text(label).font(.caption).foregroundStyle(.secondary).lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(.background.secondary)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}
