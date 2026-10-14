import SwiftUI
import Combine

struct StoreSearchResponse: Decodable {
    let resultCount: Int
    let results: [StoreApp]
}

struct StoreApp: Decodable, Identifiable {
    let trackId: Int
    let trackName: String
    let artistName: String
    let artworkUrl512: URL?
    let description: String?
    let formattedPrice: String?
    let averageUserRating: Double?
    let trackViewUrl: URL?

    var id: Int { trackId }
}

@MainActor
final class AppSearchModel: ObservableObject {
    @Published var term = ""
    @Published private(set) var apps: [StoreApp] = []
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

    func search() async {
        let query = term.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else {
            apps = []
            errorMessage = "Enter an app name to search."
            return
        }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        var components = URLComponents(string: "https://itunes.apple.com/search")!
        components.queryItems = [
            URLQueryItem(name: "term", value: query),
            URLQueryItem(name: "entity", value: "software"),
            URLQueryItem(name: "country", value: "us"),
            URLQueryItem(name: "limit", value: "25")
        ]

        guard let url = components.url else {
            errorMessage = "Could not create the search URL."
            return
        }

        do {
            var request = URLRequest(url: url)
            request.timeoutInterval = 15
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let http = response as? HTTPURLResponse,
                  (200..<300).contains(http.statusCode) else {
                throw URLError(.badServerResponse)
            }

            let decoded = try JSONDecoder().decode(StoreSearchResponse.self, from: data)
            apps = decoded.results
            if apps.isEmpty {
                errorMessage = "No matching apps were found."
            }
        } catch {
            apps = []
            errorMessage = "Search failed. Check your connection and try again."
        }
    }
}

struct AppSearchView: View {
    @StateObject private var model = AppSearchModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 14) {
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)

                    TextField("Search apps, like Snapchat", text: $model.term)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .submitLabel(.search)
                        .onSubmit { Task { await model.search() } }

                    Button {
                        Task { await model.search() }
                    } label: {
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.red)
                    }
                    .disabled(model.isLoading)
                    .accessibilityLabel("Search App Store")
                }
                .padding(14)
                .background(Color(uiColor: .secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 15))
                .padding(.horizontal)

                if model.isLoading {
                    ProgressView("Searching Apple's catalog…")
                        .tint(.red)
                        .padding(.top, 8)
                }

                if let message = model.errorMessage {
                    Text(message)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                List(model.apps) { app in
                    HStack(alignment: .top, spacing: 12) {
                        AsyncImage(url: app.artworkUrl512) { phase in
                            if let image = phase.image {
                                image.resizable().scaledToFill()
                            } else {
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color.red.opacity(0.12))
                                    .overlay {
                                        Image(systemName: "app.fill")
                                            .foregroundStyle(.red)
                                    }
                            }
                        }
                        .frame(width: 66, height: 66)
                        .clipShape(RoundedRectangle(cornerRadius: 14))

                        VStack(alignment: .leading, spacing: 5) {
                            Text(app.trackName)
                                .font(.headline)
                                .foregroundStyle(.primary)

                            Text(app.artistName)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)

                            HStack(spacing: 8) {
                                if let price = app.formattedPrice, !price.isEmpty {
                                    Text(price)
                                }
                                if let rating = app.averageUserRating {
                                    Label(String(format: "%.1f", rating), systemImage: "star.fill")
                                }
                            }
                            .font(.caption)
                            .foregroundStyle(.secondary)

                            if let storeURL = app.trackViewUrl {
                                Link(destination: storeURL) {
                                    Label("View in App Store", systemImage: "arrow.up.right.square")
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(.red)
                                }
                                .padding(.top, 3)
                            }
                        }
                    }
                    .padding(.vertical, 6)
                    .listRowBackground(Color(uiColor: .secondarySystemBackground).opacity(0.35))
                }
                .listStyle(.plain)
                .overlay {
                    if model.apps.isEmpty && !model.isLoading && model.errorMessage == nil {
                        ContentUnavailableView(
                            "Find an app",
                            systemImage: "app.badge",
                            description: Text("Search Apple's catalog for apps and open their official App Store pages.")
                        )
                    }
                }
            }
            .background(Color(uiColor: .systemBackground))
            .navigationTitle("App Catalog")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 6) {
                        Image(systemName: "app.badge")
                            .foregroundStyle(.red)
                        Text("App Catalog")
                            .font(.headline)
                    }
                }
            }
        }
        .tint(.red)
        .preferredColorScheme(.dark)
    }
}

@main
struct ITunesCatalogApp: App {
    var body: some Scene {
        WindowGroup {
            AppSearchView()
        }
    }
}
