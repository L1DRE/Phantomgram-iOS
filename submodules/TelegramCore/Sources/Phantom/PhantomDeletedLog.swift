import Foundation
import Postbox

/// A journal of the messages Phantomgram kept after the server deleted them, newest first.
///
/// The messages themselves stay in the chats; this only remembers where they are, so that they can
/// be listed without scanning every chat. Kept in UserDefaults and capped, so it stays small.
public enum PhantomDeletedLog {
    public struct Entry: Equatable {
        public let peerId: Int64
        public let messageNamespace: Int32
        public let messageId: Int32
        public let authorId: Int64?
        /// When the message was sent (unix time).
        public let timestamp: Int32
        /// When this device learned about the deletion (unix time).
        public let deletedDate: Int32
        /// The beginning of the text; empty for a message without text.
        public let text: String
        public let hasMedia: Bool

        public var id: MessageId {
            return MessageId(peerId: PeerId(self.peerId), namespace: self.messageNamespace, id: self.messageId)
        }

        fileprivate var dictionary: [String: Any] {
            var result: [String: Any] = [
                "p": NSNumber(value: self.peerId),
                "n": NSNumber(value: self.messageNamespace),
                "i": NSNumber(value: self.messageId),
                "t": NSNumber(value: self.timestamp),
                "d": NSNumber(value: self.deletedDate),
                "x": self.text,
                "m": self.hasMedia
            ]
            if let authorId = self.authorId {
                result["a"] = NSNumber(value: authorId)
            }
            return result
        }

        fileprivate init?(dictionary: [String: Any]) {
            guard let peerId = dictionary["p"] as? NSNumber, let namespace = dictionary["n"] as? NSNumber, let id = dictionary["i"] as? NSNumber else {
                return nil
            }
            self.peerId = peerId.int64Value
            self.messageNamespace = namespace.int32Value
            self.messageId = id.int32Value
            self.authorId = (dictionary["a"] as? NSNumber)?.int64Value
            self.timestamp = (dictionary["t"] as? NSNumber)?.int32Value ?? 0
            self.deletedDate = (dictionary["d"] as? NSNumber)?.int32Value ?? 0
            self.text = dictionary["x"] as? String ?? ""
            self.hasMedia = dictionary["m"] as? Bool ?? false
        }

        fileprivate init(message: Message, deletedDate: Int32) {
            self.peerId = message.id.peerId.toInt64()
            self.messageNamespace = message.id.namespace
            self.messageId = message.id.id
            self.authorId = message.author?.id.toInt64()
            self.timestamp = message.timestamp
            self.deletedDate = deletedDate
            self.text = String(message.text.prefix(PhantomDeletedLog.maximumTextLength))
            self.hasMedia = !message.media.isEmpty
        }
    }

    public static let didChangeNotification = Notification.Name("PhantomDeletedLogDidChange")

    private static let key = "phantom.deletedLog"
    private static let maximumCount = 500
    fileprivate static let maximumTextLength = 160
    private static let lock = NSLock()

    public static var entries: [Entry] {
        lock.lock()
        defer { lock.unlock() }
        return loadEntries()
    }

    private static func loadEntries() -> [Entry] {
        guard let stored = UserDefaults.standard.array(forKey: key) as? [[String: Any]] else {
            return []
        }
        return stored.compactMap(Entry.init(dictionary:))
    }

    private static func storeEntries(_ entries: [Entry]) {
        UserDefaults.standard.set(entries.map(\.dictionary), forKey: key)
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: PhantomDeletedLog.didChangeNotification, object: nil)
        }
    }

    static func add(message: Message, deletedDate: Int32) {
        lock.lock()
        defer { lock.unlock() }
        var entries = loadEntries()
        let entry = Entry(message: message, deletedDate: deletedDate)
        entries.removeAll(where: { $0.peerId == entry.peerId && $0.messageNamespace == entry.messageNamespace && $0.messageId == entry.messageId })
        entries.insert(entry, at: 0)
        if entries.count > maximumCount {
            entries.removeLast(entries.count - maximumCount)
        }
        storeEntries(entries)
    }

    /// Forgets the journal. The kept messages stay in their chats.
    public static func clear() {
        lock.lock()
        defer { lock.unlock() }
        storeEntries([])
    }
}
