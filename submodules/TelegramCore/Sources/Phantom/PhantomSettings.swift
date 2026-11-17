import Foundation

/// Phantomgram privacy settings for this fork.
///
/// Values live in the main app's UserDefaults, so they are per-device and survive app updates.
/// Every flag defaults to the stock Telegram behaviour, so an untouched install acts like the
/// official client.
public enum PhantomSettings {
    public static let didChangeNotification = Notification.Name("PhantomSettingsDidChange")

    /// The mod's own version, shown next to Telegram's in the Phantomgram settings.
    public static let modVersion = "1.4"

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
        static let hideStories = "phantom.hideStories"
        static let hidePhoneNumber = "phantom.hidePhoneNumber"
        static let compactSettingsMenu = "phantom.compactSettingsMenu"
        static let keepDisappearingPhotos = "phantom.keepDisappearingPhotos"
        static let confirmStickers = "phantom.confirmStickers"
        static let confirmGifs = "phantom.confirmGifs"
        static let stripLinkTracking = "phantom.stripLinkTracking"
        static let disableLinkPreviews = "phantom.disableLinkPreviews"
        static let hideContactsTab = "phantom.hideContactsTab"
        static let hideGiftButton = "phantom.hideGiftButton"
        static let ghostExceptions = "phantom.ghostExceptions"
        static let confirmCalls = "phantom.confirmCalls"
        static let bypassCopyProtection = "phantom.bypassCopyProtection"
        static let shakeTogglesGhost = "phantom.shakeTogglesGhost"
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

    /// Ignore client-side noforwards checks. Server-side forwarding can still be rejected.
    public static var bypassCopyProtection: Bool {
        get { return bool(Key.bypassCopyProtection, default: false) }
        set { set(newValue, Key.bypassCopyProtection) }
    }

    /// Keep incoming timer and view-once photos on this device. Enable before opening them.
    public static var keepDisappearingPhotos: Bool {
        get { return bool(Key.keepDisappearingPhotos, default: false) }
        set { set(newValue, Key.keepDisappearingPhotos) }
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

    /// Hide the stories row above the chat list (and stories of archived chats).
    public static var hideStories: Bool {
        get { return bool(Key.hideStories, default: false) }
        set { set(newValue, Key.hideStories) }
    }

    /// Hide the account's phone number under the name at the top of Settings.
    public static var hidePhoneNumber: Bool {
        get { return bool(Key.hidePhoneNumber, default: false) }
        set { set(newValue, Key.hidePhoneNumber) }
    }

    /// Hide Premium, Stars, TON, Business and gift entries from the Settings menu.
    public static var compactSettingsMenu: Bool {
        get { return bool(Key.compactSettingsMenu, default: false) }
        set { set(newValue, Key.compactSettingsMenu) }
    }

    /// Ask before sending a sticker.
    public static var confirmStickers: Bool {
        get { return bool(Key.confirmStickers, default: false) }
        set { set(newValue, Key.confirmStickers) }
    }

    /// Ask before sending a GIF.
    public static var confirmGifs: Bool {
        get { return bool(Key.confirmGifs, default: false) }
        set { set(newValue, Key.confirmGifs) }
    }

    /// Ask before starting a call.
    public static var confirmCalls: Bool {
        get { return bool(Key.confirmCalls, default: false) }
        set { set(newValue, Key.confirmCalls) }
    }

    /// Shaking the device turns ghost mode on or off.
    public static var shakeTogglesGhost: Bool {
        get { return bool(Key.shakeTogglesGhost, default: false) }
        set { set(newValue, Key.shakeTogglesGhost) }
    }

    /// Remove tracking parameters (utm_*, fbclid, …) from links in outgoing messages.
    public static var stripLinkTracking: Bool {
        get { return bool(Key.stripLinkTracking, default: false) }
        set { set(newValue, Key.stripLinkTracking) }
    }

    /// Send links without a preview.
    public static var disableLinkPreviews: Bool {
        get { return bool(Key.disableLinkPreviews, default: false) }
        set { set(newValue, Key.disableLinkPreviews) }
    }

    /// Remove the Contacts tab. Applies at the next launch.
    public static var hideContactsTab: Bool {
        get { return bool(Key.hideContactsTab, default: false) }
        set { set(newValue, Key.hideContactsTab) }
    }

    /// Hide the gift button in the message field of private chats.
    public static var hideGiftButton: Bool {
        get { return bool(Key.hideGiftButton, default: false) }
        set { set(newValue, Key.hideGiftButton) }
    }

    /// Chats that get read receipts and typing statuses even in ghost mode, as raw peer ids.
    public static var ghostExceptions: Set<Int64> {
        get {
            let values = UserDefaults.standard.array(forKey: Key.ghostExceptions) as? [NSNumber] ?? []
            return Set(values.map { $0.int64Value })
        }
        set {
            UserDefaults.standard.set(newValue.sorted().map { NSNumber(value: $0) }, forKey: Key.ghostExceptions)
            NotificationCenter.default.post(name: PhantomSettings.didChangeNotification, object: nil)
        }
    }

    public static func isGhostException(_ peerId: Int64) -> Bool {
        guard let values = UserDefaults.standard.array(forKey: Key.ghostExceptions) as? [NSNumber] else {
            return false
        }
        return values.contains(where: { $0.int64Value == peerId })
    }

    public static func setGhostException(_ peerId: Int64, _ value: Bool) {
        var exceptions = ghostExceptions
        if value {
            exceptions.insert(peerId)
        } else {
            exceptions.remove(peerId)
        }
        ghostExceptions = exceptions
    }

    private static let exportedBoolKeys: [String] = [
        Key.sendReadMessages, Key.sendOnlinePackets, Key.sendTyping, Key.saveDeletedMessages, Key.saveEditsHistory,
        Key.sendStoriesSeen, Key.sendContentConsumed, Key.markReadOnSend, Key.showMessageSeconds, Key.hideSponsoredMessages,
        Key.showPeerId, Key.hideStories, Key.hidePhoneNumber, Key.compactSettingsMenu, Key.confirmStickers, Key.confirmGifs,
        Key.stripLinkTracking, Key.disableLinkPreviews, Key.hideContactsTab, Key.hideGiftButton,
        Key.confirmCalls, Key.shakeTogglesGhost, Key.bypassCopyProtection
    ]

    /// The switches and the ghost exceptions as JSON, to carry over to another install.
    public static func exportedSettings() -> String {
        var values: [String: Any] = [:]
        let defaults = UserDefaults.standard
        for key in exportedBoolKeys where defaults.object(forKey: key) != nil {
            values[key] = defaults.bool(forKey: key)
        }
        values[Key.ghostExceptions] = ghostExceptions.sorted()
        values["phantom.export"] = 1
        guard let data = try? JSONSerialization.data(withJSONObject: values, options: [.sortedKeys]), let string = String(data: data, encoding: .utf8) else {
            return "{}"
        }
        return string
    }

    /// Applies what `exportedSettings` produced. Returns false when the text is not such an export.
    public static func importSettings(_ string: String) -> Bool {
        guard let data = string.data(using: .utf8), let values = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any], values["phantom.export"] != nil else {
            return false
        }
        let defaults = UserDefaults.standard
        for key in exportedBoolKeys {
            if let value = values[key] as? Bool {
                defaults.set(value, forKey: key)
            }
        }
        if let exceptions = values[Key.ghostExceptions] as? [NSNumber] {
            defaults.set(exceptions, forKey: Key.ghostExceptions)
        }
        NotificationCenter.default.post(name: PhantomSettings.didChangeNotification, object: nil)
        return true
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
