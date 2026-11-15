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

    /// Ghost mode is on when nothing that reveals activity is sent.
    public static var ghostMode: Bool {
        get { return !sendReadMessages && !sendOnlinePackets && !sendTyping }
        set {
            let send = !newValue
            UserDefaults.standard.set(send, forKey: Key.sendReadMessages)
            UserDefaults.standard.set(send, forKey: Key.sendOnlinePackets)
            UserDefaults.standard.set(send, forKey: Key.sendTyping)
            NotificationCenter.default.post(name: PhantomSettings.didChangeNotification, object: nil)
        }
    }
}
