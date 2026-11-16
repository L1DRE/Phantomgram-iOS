import Foundation

/// Facts about this install: when its signature runs out and whether a newer build exists.
public enum PhantomInstall {
    /// When the provisioning profile the app was signed with expires. A free Apple ID signs for
    /// seven days; after that the app no longer launches until it is installed again.
    public static let signatureExpirationDate: Date? = {
        guard let url = Bundle.main.url(forResource: "embedded", withExtension: "mobileprovision"), let data = try? Data(contentsOf: url) else {
            return nil
        }
        // The profile is a signed container with the plist in the clear inside it.
        guard let start = data.range(of: Data("<?xml".utf8)), let end = data.range(of: Data("</plist>".utf8), in: start.lowerBound ..< data.count) else {
            return nil
        }
        let plistData = data.subdata(in: start.lowerBound ..< end.upperBound)
        guard let plist = (try? PropertyListSerialization.propertyList(from: plistData, options: [], format: nil)) as? [String: Any] else {
            return nil
        }
        return plist["ExpirationDate"] as? Date
    }()

    /// Whole days until the signature expires, rounded down; negative when it already has.
    public static var signatureDaysLeft: Int? {
        guard let date = signatureExpirationDate else {
            return nil
        }
        return Int(floor(date.timeIntervalSinceNow / 86400.0))
    }

    /// The build number of this install.
    public static var buildNumber: Int {
        return (Bundle.main.infoDictionary?["CFBundleVersion"] as? String).flatMap { Int($0) } ?? 0
    }

    public struct Update: Equatable {
        public let buildNumber: Int
        public let title: String
        public let url: String
    }

    public enum UpdateCheckResult: Equatable {
        case upToDate
        case available(Update)
        case failed
    }

    // The CI numbers a build as build_number_offset + the workflow's run number.
    private static let buildNumberOffset = 3730
    private static let latestRunUrl = "https://api.github.com/repos/L1DRE/Phantomgram-iOS/actions/workflows/phantomgram.yml/runs?branch=phantomgram&status=success&per_page=1"

    /// Asks GitHub for the latest successful build of the fork. Calls back on the main queue.
    public static func checkForUpdate(completion: @escaping (UpdateCheckResult) -> Void) {
        guard let url = URL(string: latestRunUrl) else {
            completion(.failed)
            return
        }
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 15.0)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        let currentBuildNumber = buildNumber
        let task = URLSession.shared.dataTask(with: request, completionHandler: { data, _, _ in
            var result: UpdateCheckResult = .failed
            if let data = data, let root = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any], let runs = root["workflow_runs"] as? [[String: Any]] {
                if let run = runs.first, let runNumber = run["run_number"] as? Int, let pageUrl = run["html_url"] as? String {
                    let latestBuildNumber = buildNumberOffset + runNumber
                    if latestBuildNumber > currentBuildNumber {
                        result = .available(Update(buildNumber: latestBuildNumber, title: run["display_title"] as? String ?? "", url: pageUrl))
                    } else {
                        result = .upToDate
                    }
                } else {
                    result = .upToDate
                }
            }
            DispatchQueue.main.async {
                completion(result)
            }
        })
        task.resume()
    }
}
