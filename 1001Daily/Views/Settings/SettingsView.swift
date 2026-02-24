import SwiftUI

struct SettingsView: View {
    @Environment(\.appEnvironment) private var env
    @State private var showingResetConfirm = false
    var onHistory: (() -> Void)? = nil

    var body: some View {
        Form {
            Section {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Movies watched")
                            .font(.subheadline)
                        Text("\(env.viewModel.movieCompletedCount) of 1001")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "film.stack")
                        .foregroundStyle(.indigo)
                }

                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Albums listened")
                            .font(.subheadline)
                        Text("\(env.viewModel.albumCompletedCount) of 1001")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "music.note.list")
                        .foregroundStyle(.purple)
                }
            } header: {
                Label("Progress", systemImage: "chart.bar.fill")
            }

            Section {
                HStack(spacing: 12) {
                    Image(systemName: "popcorn.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(.indigo)
                        .frame(width: 40)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("1oo1")
                            .font(.system(size: 13, weight: .semibold))
                        Text("Made by Axel Marazzi")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        HStack(spacing: 3) {
                            Text("More silly apps at")
                                .foregroundStyle(.secondary)
                            Link("axelhaciendo.cosas ↗", destination: URL(string: "https://axelhaciendo.cosas")!)
                                .foregroundStyle(.indigo)
                        }
                        .font(.caption)
                    }
                }
                .padding(.vertical, 4)
            } header: {
                Label("About", systemImage: "info.circle")
            }

            Section {
                Button(role: .destructive) {
                    showingResetConfirm = true
                } label: {
                    Label("Reset All Data", systemImage: "trash")
                }
            } header: {
                Label("Danger Zone", systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(.red)
            } footer: {
                Text("This will permanently delete all your history, ratings, and notes. The recommendation lists will remain intact.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .alert("Reset All Data?", isPresented: $showingResetConfirm) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                Task { await env.viewModel.resetAllData() }
            }
        } message: {
            Text("This will delete all your history, ratings, and notes. This action cannot be undone.")
        }
        .task {
            await env.viewModel.loadProgress()
        }
    }

    // Expose loadProgress for external calls
    private func loadProgress() async {
        await env.viewModel.loadHistory()
    }
}
