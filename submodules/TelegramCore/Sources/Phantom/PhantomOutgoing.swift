import Foundation
import Postbox

private let phantomTrackingParameterNames: Set<String> = [
    "fbclid", "gclid", "gclsrc", "dclid", "gbraid", "wbraid", "yclid", "ysclid", "msclkid", "twclid", "ttclid",
    "igshid", "igsh", "mc_cid", "mc_eid", "_hsenc", "_hsmi", "hsctatracking", "vero_id", "oly_enc_id", "oly_anon_id",
    "s_cid", "ref_src", "ref_url", "mkt_tok", "_openstat", "srsltid"
]

private func phantomIsTrackingParameter(name: String, host: String) -> Bool {
    if name.hasPrefix("utm_") || phantomTrackingParameterNames.contains(name) {
        return true
    }
    // Share identifiers that mean something else on other sites.
    if name == "si" {
        return host.hasSuffix("youtube.com") || host.hasSuffix("youtu.be") || host.hasSuffix("spotify.com")
    }
    if name == "s" || name == "t" {
        return host == "x.com" || host == "twitter.com" || host.hasSuffix(".x.com") || host.hasSuffix(".twitter.com")
    }
    return false
}

/// The link without tracking parameters; everything else is left exactly as written.
public func phantomLinkWithoutTracking(_ link: String) -> String {
    guard let queryStart = link.firstIndex(of: "?") else {
        return link
    }
    let base = link[..<queryStart]
    var query = link[link.index(after: queryStart)...]
    var fragment = ""
    if let fragmentStart = query.firstIndex(of: "#") {
        fragment = String(query[fragmentStart...])
        query = query[..<fragmentStart]
    }

    var host = String(base).lowercased()
    if let schemeEnd = host.range(of: "://") {
        host = String(host[schemeEnd.upperBound...])
    }
    if let pathStart = host.firstIndex(of: "/") {
        host = String(host[..<pathStart])
    }

    let parameters = query.split(separator: "&", omittingEmptySubsequences: true)
    let kept = parameters.filter { parameter in
        let name = parameter.split(separator: "=", maxSplits: 1, omittingEmptySubsequences: false).first.flatMap { String($0).lowercased() } ?? ""
        return !phantomIsTrackingParameter(name: name, host: host)
    }
    if kept.count == parameters.count {
        return link
    }
    var result = String(base)
    if !kept.isEmpty {
        result += "?" + kept.joined(separator: "&")
    }
    result += fragment
    return result
}

private let phantomLinkDetector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)

/// Removes tracking parameters from every link in the text and moves the entities accordingly
/// (entity ranges are UTF-16 offsets, as NSString's are).
func phantomTextWithoutLinkTracking(text: String, entities: [MessageTextEntity]) -> (String, [MessageTextEntity])? {
    guard let detector = phantomLinkDetector, text.contains("?") else {
        return nil
    }
    let mutableText = NSMutableString(string: text)
    var entities = entities
    var changed = false
    let matches = detector.matches(in: text, options: [], range: NSRange(location: 0, length: mutableText.length))
    for match in matches.reversed() {
        guard let scheme = match.url?.scheme?.lowercased(), scheme == "http" || scheme == "https" else {
            continue
        }
        let link = mutableText.substring(with: match.range)
        let cleaned = phantomLinkWithoutTracking(link)
        if cleaned == link {
            continue
        }
        let delta = (cleaned as NSString).length - match.range.length
        let end = match.range.location + match.range.length
        mutableText.replaceCharacters(in: match.range, with: cleaned)
        for i in 0 ..< entities.count {
            var lower = entities[i].range.lowerBound
            var upper = entities[i].range.upperBound
            if lower >= end {
                lower += delta
                upper += delta
            } else if upper >= end {
                upper = max(lower, upper + delta)
            } else if upper > match.range.location + (cleaned as NSString).length {
                // Ended inside the part that was cut off.
                upper = max(lower, match.range.location + (cleaned as NSString).length)
            }
            entities[i].range = lower ..< upper
        }
        changed = true
    }
    if !changed {
        return nil
    }
    return (mutableText as String, entities.filter { !$0.range.isEmpty })
}

/// Applied to everything the user sends: link cleaning and "no link previews".
func phantomPreparedOutgoingMessages(_ messages: [EnqueueMessage]) -> [EnqueueMessage] {
    let stripTracking = PhantomSettings.stripLinkTracking
    let disablePreviews = PhantomSettings.disableLinkPreviews
    if !stripTracking && !disablePreviews {
        return messages
    }
    return messages.map { message -> EnqueueMessage in
        guard case let .message(text, attributes, inlineStickers, mediaReference, threadId, replyToMessageId, replyToStoryId, localGroupingKey, correlationId, bubbleUpEmojiOrStickersets) = message else {
            return message
        }
        // A rich message keeps its text in a page of its own; leave those alone.
        if attributes.contains(where: { $0 is RichTextMessageAttribute }) {
            return message
        }
        var text = text
        var attributes = attributes
        var mediaReference = mediaReference

        if stripTracking {
            let currentEntities = (attributes.first(where: { $0 is TextEntitiesMessageAttribute }) as? TextEntitiesMessageAttribute)?.entities ?? []
            if let (updatedText, updatedEntities) = phantomTextWithoutLinkTracking(text: text, entities: currentEntities) {
                text = updatedText
                if let index = attributes.firstIndex(where: { $0 is TextEntitiesMessageAttribute }) {
                    attributes[index] = TextEntitiesMessageAttribute(entities: updatedEntities)
                }
            }
        }

        if disablePreviews {
            if let media = mediaReference?.media, media is TelegramMediaWebpage {
                mediaReference = nil
            }
            if mediaReference == nil {
                var flags: OutgoingContentInfoFlags = [.disableLinkPreviews]
                if let index = attributes.firstIndex(where: { $0 is OutgoingContentInfoMessageAttribute }) {
                    if let current = attributes[index] as? OutgoingContentInfoMessageAttribute {
                        flags.formUnion(current.flags)
                    }
                    attributes[index] = OutgoingContentInfoMessageAttribute(flags: flags)
                } else {
                    attributes.append(OutgoingContentInfoMessageAttribute(flags: flags))
                }
            }
        }

        return .message(text: text, attributes: attributes, inlineStickers: inlineStickers, mediaReference: mediaReference, threadId: threadId, replyToMessageId: replyToMessageId, replyToStoryId: replyToStoryId, localGroupingKey: localGroupingKey, correlationId: correlationId, bubbleUpEmojiOrStickersets: bubbleUpEmojiOrStickersets)
    }
}
