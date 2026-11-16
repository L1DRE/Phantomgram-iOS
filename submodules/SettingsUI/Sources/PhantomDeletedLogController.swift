import Foundation
import UIKit
import Display
import SwiftSignalKit
import TelegramCore
import TelegramPresentationData
import ItemListUI
import PresentationDataUtils
import AccountContext
import LocalizedPeerData

private final class PhantomDeletedLogArguments {
    let context: AccountContext
    let open: (PhantomDeletedLog.Entry) -> Void
    let clear: () -> Void

    init(context: AccountContext, open: @escaping (PhantomDeletedLog.Entry) -> Void, clear: @escaping () -> Void) {
        self.context = context
        self.open = open
        self.clear = clear
    }
}

private enum PhantomDeletedLogSection: Int32 {
    case messages
    case clear
}

private enum PhantomDeletedLogEntry: ItemListNodeEntry {
    case message(Int32, PhantomDeletedLog.Entry, EnginePeer?, String, String)
    case empty(String)
    case clear(String)

    var section: ItemListSectionId {
        switch self {
        case .message, .empty:
            return PhantomDeletedLogSection.messages.rawValue
        case .clear:
            return PhantomDeletedLogSection.clear.rawValue
        }
    }

    var stableId: Int32 {
        switch self {
        case let .message(index, _, _, _, _):
            return index
        case .empty:
            return Int32.max - 1
        case .clear:
            return Int32.max
        }
    }

    static func <(lhs: PhantomDeletedLogEntry, rhs: PhantomDeletedLogEntry) -> Bool {
        return lhs.stableId < rhs.stableId
    }

    func item(presentationData: ItemListPresentationData, arguments: Any) -> ListViewItem {
        let arguments = arguments as! PhantomDeletedLogArguments
        switch self {
        case let .message(_, entry, peer, title, text):
            return ItemListDisclosureItem(presentationData: presentationData, systemStyle: .glass, context: arguments.context, iconPeer: peer, title: title, label: text, labelStyle: .multilineDetailText, sectionId: self.section, style: .blocks, disclosureStyle: .arrow, action: {
                arguments.open(entry)
            })
        case let .empty(text):
            return ItemListTextItem(presentationData: presentationData, text: .plain(text), sectionId: self.section)
        case let .clear(title):
            return ItemListActionItem(presentationData: presentationData, systemStyle: .glass, title: title, kind: .destructive, alignment: .natural, sectionId: self.section, style: .blocks, action: {
                arguments.clear()
            })
        }
    }
}

private func phantomDeletedLogEntries(entries: [PhantomDeletedLog.Entry], peers: [EnginePeer.Id: EnginePeer], isRussian: Bool, presentationData: PresentationData) -> [PhantomDeletedLogEntry] {
    var result: [PhantomDeletedLogEntry] = []
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .short

    var index: Int32 = 0
    for entry in entries {
        // Entries of other accounts on this device resolve to no peer here: skip them.
        guard let peer = peers[entry.id.peerId] else {
            continue
        }
        var title = peer.displayTitle(strings: presentationData.strings, displayOrder: presentationData.nameDisplayOrder)
        if let authorId = entry.authorId, authorId != entry.peerId, let author = peers[EnginePeer.Id(authorId)] {
            title = author.compactDisplayTitle + " · " + title
        }
        var text = entry.text
        if text.isEmpty {
            text = entry.hasMedia ? (isRussian ? "Медиа" : "Media") : (isRussian ? "Сообщение" : "Message")
        }
        let deletedText = (isRussian ? "Удалено " : "Deleted ") + formatter.string(from: Date(timeIntervalSince1970: Double(entry.deletedDate)))
        result.append(.message(index, entry, peer, title, text + "\n" + deletedText))
        index += 1
    }

    if result.isEmpty {
        result.append(.empty(isRussian ? "Здесь появятся сообщения, которые собеседники удалили, пока включено «Сохранять удалённые сообщения»." : "Messages other people delete while Save Deleted Messages is on will be listed here."))
    } else {
        result.append(.clear(isRussian ? "Очистить журнал" : "Clear the Journal"))
    }
    return result
}

/// The messages Phantomgram kept after they were deleted, newest first; a row opens the chat at the message.
func phantomDeletedLogController(context: AccountContext) -> ViewController {
    let entriesPromise = ValuePromise(PhantomDeletedLog.entries, ignoreRepeated: true)

    var openImpl: ((PhantomDeletedLog.Entry) -> Void)?

    let arguments = PhantomDeletedLogArguments(context: context, open: { entry in
        openImpl?(entry)
    }, clear: {
        PhantomDeletedLog.clear()
        entriesPromise.set([])
    })

    let observer = NotificationCenter.default.addObserver(forName: PhantomDeletedLog.didChangeNotification, object: nil, queue: .main, using: { _ in
        entriesPromise.set(PhantomDeletedLog.entries)
    })

    let peersSignal: Signal<([PhantomDeletedLog.Entry], [EnginePeer.Id: EnginePeer]), NoError> = entriesPromise.get()
    |> mapToSignal { entries -> Signal<([PhantomDeletedLog.Entry], [EnginePeer.Id: EnginePeer]), NoError> in
        var peerIds = Set<EnginePeer.Id>()
        for entry in entries {
            peerIds.insert(entry.id.peerId)
            if let authorId = entry.authorId {
                peerIds.insert(EnginePeer.Id(authorId))
            }
        }
        return context.engine.data.get(EngineDataMap(peerIds.map(TelegramEngine.EngineData.Item.Peer.Peer.init(id:))))
        |> map { peers -> ([PhantomDeletedLog.Entry], [EnginePeer.Id: EnginePeer]) in
            var result: [EnginePeer.Id: EnginePeer] = [:]
            for (id, peer) in peers {
                if let peer = peer {
                    result[id] = peer
                }
            }
            return (entries, result)
        }
    }

    let signal = combineLatest(queue: .mainQueue(),
        context.sharedContext.presentationData,
        peersSignal
    )
    |> map { presentationData, data -> (ItemListControllerState, (ItemListNodeState, Any)) in
        var presentationData = presentationData
        presentationData = presentationData.withUpdated(theme: presentationData.theme.withModalBlocksBackground())
        let isRussian = presentationData.strings.primaryComponent.languageCode.hasPrefix("ru")

        let controllerState = ItemListControllerState(presentationData: ItemListPresentationData(presentationData), title: .text(isRussian ? "Удалённые" : "Deleted"), leftNavigationButton: nil, rightNavigationButton: nil, backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Back))
        let listState = ItemListNodeState(presentationData: ItemListPresentationData(presentationData), entries: phantomDeletedLogEntries(entries: data.0, peers: data.1, isRussian: isRussian, presentationData: presentationData), style: .blocks, animateChanges: false)

        return (controllerState, (listState, arguments))
    }
    |> afterDisposed {
        NotificationCenter.default.removeObserver(observer)
    }

    let controller = ItemListController(context: context, state: signal)
    openImpl = { [weak controller] entry in
        guard let navigationController = controller?.navigationController as? NavigationController else {
            return
        }
        let _ = (context.engine.data.get(TelegramEngine.EngineData.Item.Peer.Peer(id: entry.id.peerId))
        |> deliverOnMainQueue).start(next: { peer in
            guard let peer = peer else {
                return
            }
            context.sharedContext.navigateToChatController(NavigateToChatControllerParams(navigationController: navigationController, context: context, chatLocation: .peer(peer), subject: .message(id: .id(entry.id), highlight: ChatControllerSubject.MessageHighlight(quote: nil), timecode: nil, setupReply: false)))
        })
    }
    return controller
}
