import Foundation
import Postbox

/// Marks a message that the server deleted but Phantomgram kept on this device.
public final class PhantomDeletedMessageAttribute: MessageAttribute {
    /// When this device learned about the deletion (unix time).
    public let date: Int32

    public init(date: Int32) {
        self.date = date
    }

    public required init(decoder: PostboxDecoder) {
        self.date = decoder.decodeInt32ForKey("d", orElse: 0)
    }

    public func encode(_ encoder: PostboxEncoder) {
        encoder.encodeInt32(self.date, forKey: "d")
    }
}

/// Earlier texts of an edited message, oldest first.
public final class PhantomEditHistoryMessageAttribute: MessageAttribute {
    public struct Entry: Equatable {
        public let text: String
        /// When this text was replaced (unix time).
        public let date: Int32

        public init(text: String, date: Int32) {
            self.text = text
            self.date = date
        }
    }

    public let entries: [Entry]

    public init(entries: [Entry]) {
        self.entries = entries
    }

    public required init(decoder: PostboxDecoder) {
        let texts = decoder.decodeStringArrayForKey("t")
        let dates = decoder.decodeInt32ArrayForKey("d")
        var entries: [Entry] = []
        for i in 0 ..< min(texts.count, dates.count) {
            entries.append(Entry(text: texts[i], date: dates[i]))
        }
        self.entries = entries
    }

    public func encode(_ encoder: PostboxEncoder) {
        encoder.encodeStringArray(self.entries.map(\.text), forKey: "t")
        encoder.encodeInt32Array(self.entries.map(\.date), forKey: "d")
    }
}

public extension Message {
    /// Photo-only retention: ordinary chat auto-delete and outgoing media keep their timers.
    var phantomShouldKeepDisappearingPhoto: Bool {
        return PhantomSettings.keepDisappearingPhotos
            && self.flags.contains(.Incoming)
            && self.containsSecretMedia
            && self.media.contains(where: { $0 is TelegramMediaImage })
    }

    /// Set when the server deleted this message and Phantomgram kept it.
    var phantomDeletedDate: Int32? {
        for attribute in self.attributes {
            if let attribute = attribute as? PhantomDeletedMessageAttribute {
                return attribute.date
            }
        }
        return nil
    }

    /// Earlier versions of the text, oldest first; empty when none were saved.
    var phantomEditHistory: [PhantomEditHistoryMessageAttribute.Entry] {
        for attribute in self.attributes {
            if let attribute = attribute as? PhantomEditHistoryMessageAttribute {
                return attribute.entries
            }
        }
        return []
    }
}

public extension EngineMessage {
    /// Set when the server deleted this message and Phantomgram kept it.
    var phantomDeletedDate: Int32? {
        for attribute in self.attributes {
            if let attribute = attribute as? PhantomDeletedMessageAttribute {
                return attribute.date
            }
        }
        return nil
    }

    /// Earlier versions of the text, oldest first; empty when none were saved.
    var phantomEditHistory: [PhantomEditHistoryMessageAttribute.Entry] {
        for attribute in self.attributes {
            if let attribute = attribute as? PhantomEditHistoryMessageAttribute {
                return attribute.entries
            }
        }
        return []
    }
}

private func phantomCurrentTimestamp() -> Int32 {
    return Int32(Date().timeIntervalSince1970)
}

private func phantomStoreMessage(_ message: Message, attributes: [MessageAttribute]) -> StoreMessage {
    return StoreMessage(id: message.id, customStableId: nil, globallyUniqueId: message.globallyUniqueId, groupingKey: message.groupingKey, threadId: message.threadId, timestamp: message.timestamp, flags: StoreMessageFlags(message.flags), tags: message.tags, globalTags: message.globalTags, localTags: message.localTags, forwardInfo: message.forwardInfo.flatMap(StoreMessageForwardInfo.init), authorId: message.author?.id, text: message.text, attributes: attributes, media: message.media)
}

/// Called wherever the server tells us to remove messages. With "save deleted messages" on,
/// keeps the ones it can and marks them as deleted. Returns the ids that must still be removed.
///
/// Local and scheduled messages are not retained here. Self-destructing content is excluded
/// from Save Deleted Messages; incoming photos have their own retention switch.
func phantomKeepDeletedMessages(transaction: Transaction, ids: [MessageId]) -> [MessageId] {
    if !PhantomSettings.saveDeletedMessages && !PhantomSettings.keepDisappearingPhotos {
        return ids
    }
    let now = phantomCurrentTimestamp()
    var remaining: [MessageId] = []
    for id in ids {
        guard id.namespace == Namespaces.Message.Cloud, let message = transaction.getMessage(id) else {
            remaining.append(id)
            continue
        }
        if message.phantomShouldKeepDisappearingPhoto {
            continue
        }
        if !PhantomSettings.saveDeletedMessages {
            remaining.append(id)
            continue
        }
        if message.attributes.contains(where: { $0 is PhantomDeletedMessageAttribute }) {
            // Already kept; a repeated deletion changes nothing.
            continue
        }
        if message.attributes.contains(where: { $0 is AutoremoveTimeoutMessageAttribute || $0 is AutoclearTimeoutMessageAttribute }) {
            remaining.append(id)
            continue
        }
        transaction.updateMessage(id, update: { current in
            var attributes = current.attributes
            attributes.append(PhantomDeletedMessageAttribute(date: now))
            return .update(phantomStoreMessage(current, attributes: attributes))
        })
        PhantomDeletedLog.add(message: message, deletedDate: now)
    }
    return remaining
}

/// With "save edit history" on, carries the previous text of an edited message over into the
/// attributes the edit is about to store.
func phantomAttributesPreservingEditHistory(previous: Message, updatedText: String, updatedAttributes: [MessageAttribute]) -> [MessageAttribute] {
    var result = updatedAttributes
    // The server's version never carries our attributes: keep them across the edit.
    for attribute in previous.attributes {
        if attribute is PhantomDeletedMessageAttribute, !result.contains(where: { $0 is PhantomDeletedMessageAttribute }) {
            result.append(attribute)
        }
    }
    var entries = previous.phantomEditHistory
    if PhantomSettings.saveEditsHistory && previous.text != updatedText && !previous.text.isEmpty {
        entries.append(PhantomEditHistoryMessageAttribute.Entry(text: previous.text, date: phantomCurrentTimestamp()))
    }
    result.removeAll(where: { $0 is PhantomEditHistoryMessageAttribute })
    if !entries.isEmpty {
        result.append(PhantomEditHistoryMessageAttribute(entries: entries))
    }
    return result
}
