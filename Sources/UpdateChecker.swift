import Foundation

struct ReleaseUpdate: Equatable {
    let version: String
    let url: URL
}

enum UpdateChecker {
    static let endpoint = URL(string: "https://api.github.com/repos/numeono/minimized-windows/releases/latest")!

    private struct Release: Decodable {
        let tag_name: String
        let html_url: URL
        let draft: Bool
        let prerelease: Bool
    }

    static func versionParts(_ value: String) -> [Int]? {
        let value = value.hasPrefix("v") ? String(value.dropFirst()) : value
        let parts = value.split(separator: ".", omittingEmptySubsequences: false)
        guard !parts.isEmpty, parts.count <= 4 else { return nil }
        let numbers = parts.compactMap { part -> Int? in
            guard !part.isEmpty, part.allSatisfy({ $0.isASCII && $0.isNumber }) else { return nil }
            return Int(part)
        }
        return numbers.count == parts.count ? numbers : nil
    }

    static func isNewer(_ candidate: String, than current: String) -> Bool {
        guard let candidate = versionParts(candidate), let current = versionParts(current) else { return false }
        for index in 0..<max(candidate.count, current.count) {
            let a = index < candidate.count ? candidate[index] : 0
            let b = index < current.count ? current[index] : 0
            if a != b { return a > b }
        }
        return false
    }

    static func update(from data: Data, statusCode: Int, currentVersion: String) -> ReleaseUpdate? {
        guard statusCode == 200,
              let release = try? JSONDecoder().decode(Release.self, from: data),
              !release.draft, !release.prerelease,
              isNewer(release.tag_name, than: currentVersion),
              release.html_url.scheme == "https", release.html_url.host == "github.com",
              release.html_url.user == nil, release.html_url.password == nil,
              release.html_url.path.hasPrefix("/numeono/minimized-windows/releases/tag/") else { return nil }
        return ReleaseUpdate(version: release.tag_name, url: release.html_url)
    }

    static func check(currentVersion: String, completion: @escaping (ReleaseUpdate?) -> Void) {
        var request = URLRequest(url: endpoint, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 10)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("2022-11-28", forHTTPHeaderField: "X-GitHub-Api-Version")
        request.setValue("MinimizedWindows/\(currentVersion)", forHTTPHeaderField: "User-Agent")
        let session = URLSession(configuration: .ephemeral)
        session.dataTask(with: request) { data, response, error in
            let update: ReleaseUpdate?
            if error == nil, let data = data, let response = response as? HTTPURLResponse {
                update = self.update(from: data, statusCode: response.statusCode, currentVersion: currentVersion)
            } else {
                update = nil
            }
            session.finishTasksAndInvalidate()
            DispatchQueue.main.async { completion(update) }
        }.resume()
    }
}
