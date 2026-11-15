import Foundation

/// Phantomgram privacy settings for this fork.
///
/// Values live in the main app's UserDefaults, so they are per-device and survive app updates.
/// Every flag defaults to the stock Telegram behaviour, so an untouched install acts like the
/// official client.
public enum PhantomSettings {
    public static let didChangeNotification = Notification.Name("PhantomSettingsDidChange")

    private enum Key {
        static let sendReadMessages = "phantom.sendReadMessages"
        static let sendOnlinePackets = "phantom.sendOnlinePackets"
        static let sendTyping = "phantom.sendTyping"
        static let saveDeletedMessages = "phantom.saveDeletedMessages"
        static let saveEditsHistory = "phantom.saveEditsHistory"
        static let sendStoriesSeen = "phantom.sendStoriesSeen"
        static let sendContentConsumed = "phantom.sendContentConsumed"
        static let markReadOnSend = "phantom.markReadOnSend"
        static let showMessageSeconds = "phantom.showMessageSeconds"
        static let hideSponsoredMessages = "phantom.hideSponsoredMessages"
        static let showPeerId = "phantom.showPeerId"
    }

    private static func bool(_ key: String, default defaultValue: Bool) -> Bool {
        let defaults = UserDefaults.standard
        if defaults.object(forKey: key) == nil {
            return defaultValue
        }
        return defaults.bool(forKey: key)
    }

    private static func set(_ value: Bool, _ key: String) {
        UserDefaults.standard.set(value, forKey: key)
        NotificationCenter.default.post(name: PhantomSettings.didChangeNotification, object: nil)
    }

    /// Send read receipts ("blue ticks") for private chats, groups, channels and threads.
    public static var sendReadMessages: Bool {
        get { return bool(Key.sendReadMessages, default: true) }
        set { set(newValue, Key.sendReadMessages) }
    }

    /// Report the account as online while the app is open.
    public static var sendOnlinePackets: Bool {
        get { return bool(Key.sendOnlinePackets, default: true) }
        set { set(newValue, Key.sendOnlinePackets) }
    }

    /// Send "typing…", "recording voice…" and similar activity statuses.
    public static var sendTyping: Bool {
        get { return bool(Key.sendTyping, default: true) }
        set { set(newValue, Key.sendTyping) }
    }

    /// Keep messages that other people delete, marked as deleted, instead of removing them.
    public static var saveDeletedMessages: Bool {
        get { return bool(Key.saveDeletedMessages, default: false) }
        set { set(newValue, Key.saveDeletedMessages) }
    }

    /// Keep the previous text of edited messages.
    public static var saveEditsHistory: Bool {
        get { return bool(Key.saveEditsHistory, default: false) }
        set { set(newValue, Key.saveEditsHistory) }
    }

    /// Tell the server which stories were watched (the author sees you in the viewers list).
    public static var sendStoriesSeen: Bool {
        get { return bool(Key.sendStoriesSeen, default: true) }
        set { set(newValue, Key.sendStoriesSeen) }
    }

    /// Tell the server that voice messages, video messages and other consumable content were
    /// played (the sender sees the dot disappear). Self-destructing media keep their timers.
    public static var sendContentConsumed: Bool {
        get { return bool(Key.sendContentConsumed, default: true) }
        set { set(newValue, Key.sendContentConsumed) }
    }

    /// With read receipts off, still mark a chat as read when sending a message in it, as the
    /// official client would have done long before the reply.
    public static var markReadOnSend: Bool {
        get { return bool(Key.markReadOnSend, default: true) }
        set { set(newValue, Key.markReadOnSend) }
    }

    /// Show seconds in message timestamps.
    public static var showMessageSeconds: Bool {
        get { return bool(Key.showMessageSeconds, default: false) }
        set { set(newValue, Key.showMessageSeconds) }
    }

    /// Do not load or show sponsored messages in channels.
    public static var hideSponsoredMessages: Bool {
        get { return bool(Key.hideSponsoredMessages, default: false) }
        set { set(newValue, Key.hideSponsoredMessages) }
    }

    /// Show the user or chat ID and an estimated registration date in profiles.
    public static var showPeerId: Bool {
        get { return bool(Key.showPeerId, default: true) }
        set { set(newValue, Key.showPeerId) }
    }

    private static let ghostKeys = [Key.sendReadMessages, Key.sendOnlinePackets, Key.sendTyping, Key.sendStoriesSeen, Key.sendContentConsumed]

    /// Ghost mode is on when nothing that reveals activity is sent.
    public static var ghostMode: Bool {
        get { return !ghostKeys.contains(where: { bool($0, default: true) }) }
        set {
            for key in ghostKeys {
                UserDefaults.standard.set(!newValue, forKey: key)
            }
            NotificationCenter.default.post(name: PhantomSettings.didChangeNotification, object: nil)
        }
    }
}
