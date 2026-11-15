import Foundation
import UIKit
import Display
import SwiftSignalKit
import TelegramCore
import TelegramPresentationData
import ItemListUI
import PresentationDataUtils
import AccountContext

private final class PhantomSettingsControllerArguments {
    let updateGhostMode: (Bool) -> Void
    let updateSendReadMessages: (Bool) -> Void
    let updateSendOnlinePackets: (Bool) -> Void
    let updateSendTyping: (Bool) -> Void
    let updateSaveDeletedMessages: (Bool) -> Void
    let updateSaveEditsHistory: (Bool) -> Void

    init(
        updateGhostMode: @escaping (Bool) -> Void,
        updateSendReadMessages: @escaping (Bool) -> Void,
        updateSendOnlinePackets: @escaping (Bool) -> Void,
        updateSendTyping: @escaping (Bool) -> Void,
        updateSaveDeletedMessages: @escaping (Bool) -> Void,
        updateSaveEditsHistory: @escaping (Bool) -> Void
    ) {
        self.updateGhostMode = updateGhostMode
        self.updateSendReadMessages = updateSendReadMessages
        self.updateSendOnlinePackets = updateSendOnlinePackets
        self.updateSendTyping = updateSendTyping
        self.updateSaveDeletedMessages = updateSaveDeletedMessages
        self.updateSaveEditsHistory = updateSaveEditsHistory
    }
}

private struct PhantomSettingsState: Equatable {
    var sendReadMessages: Bool
    var sendOnlinePackets: Bool
    var sendTyping: Bool
    var saveDeletedMessages: Bool
    var saveEditsHistory: Bool

    var ghostMode: Bool {
        return !self.sendReadMessages && !self.sendOnlinePackets && !self.sendTyping
    }

    static func current() -> PhantomSettingsState {
        return PhantomSettingsState(
            sendReadMessages: PhantomSettings.sendReadMessages,
            sendOnlinePackets: PhantomSettings.sendOnlinePackets,
            sendTyping: PhantomSettings.sendTyping,
            saveDeletedMessages: PhantomSettings.saveDeletedMessages,
            saveEditsHistory: PhantomSettings.saveEditsHistory
        )
    }
}

/// The screen is not translated through PresentationStrings: Russian when the app language is
/// Russian, English otherwise.
private struct PhantomStrings {
    let title: String
    let ghostHeader: String
    let ghostMode: String
    let ghostFooter: String
    let sendRead: String
    let sendOnline: String
    let sendTyping: String
    let detailsFooter: String
    let historyHeader: String
    let saveDeleted: String
    let saveEdits: String
    let historyFooter: String

    init(languageCode: String) {
        if languageCode.hasPrefix("ru") {
            self.title = "Phantomgram"
            self.ghostHeader = "РЕЖИМ ПРИЗРАКА"
            self.ghostMode = "Режим призрака"
            self.ghostFooter = "Другие не увидят, что вы в сети, печатаете или прочитали их сообщения."
            self.sendRead = "Отправлять «прочитано»"
            self.sendOnline = "Отправлять «в сети»"
            self.sendTyping = "Отправлять «печатает»"
            self.detailsFooter = "Прочитанные сообщения остаются прочитанными только на этом устройстве."
            self.historyHeader = "ИСТОРИЯ СООБЩЕНИЙ"
            self.saveDeleted = "Сохранять удалённые сообщения"
            self.saveEdits = "Сохранять историю правок"
            self.historyFooter = "Удалённые сообщения помечаются значком 🗑 у времени. Старые версии текста — в меню сообщения, пункт «История правок». Всё хранится только на этом устройстве и только для чатов, которые были загружены. Самоуничтожающиеся сообщения не сохраняются."
        } else {
            self.title = "Phantomgram"
            self.ghostHeader = "GHOST MODE"
            self.ghostMode = "Ghost Mode"
            self.ghostFooter = "Others won't see that you are online, typing, or have read their messages."
            self.sendRead = "Send Read Receipts"
            self.sendOnline = "Send Online Status"
            self.sendTyping = "Send Typing Status"
            self.detailsFooter = "Messages you read stay read only on this device."
            self.historyHeader = "MESSAGE HISTORY"
            self.saveDeleted = "Save Deleted Messages"
            self.saveEdits = "Save Edit History"
            self.historyFooter = "Deleted messages show 🗑 next to the time. Earlier versions of a text are in the message menu under Edit History. Everything stays on this device, only for chats that were loaded. Self-destructing messages are not kept."
        }
    }
}

private enum PhantomSettingsSection: Int32 {
    case ghost
    case details
    case history
}

private enum PhantomSettingsEntry: ItemListNodeEntry {
    case ghostHeader(String)
    case ghostMode(String, Bool)
    case ghostFooter(String)
    case sendRead(String, Bool)
    case sendOnline(String, Bool)
    case sendTyping(String, Bool)
    case detailsFooter(String)
    case historyHeader(String)
    case saveDeleted(String, Bool)
    case saveEdits(String, Bool)
    case historyFooter(String)

    var section: ItemListSectionId {
        switch self {
        case .ghostHeader, .ghostMode, .ghostFooter:
            return PhantomSettingsSection.ghost.rawValue
        case .sendRead, .sendOnline, .sendTyping, .detailsFooter:
            return PhantomSettingsSection.details.rawValue
        case .historyHeader, .saveDeleted, .saveEdits, .historyFooter:
            return PhantomSettingsSection.history.rawValue
        }
    }

    var stableId: Int32 {
        switch self {
        case .ghostHeader:
            return 0
        case .ghostMode:
            return 1
        case .ghostFooter:
            return 2
        case .sendRead:
            return 3
        case .sendOnline:
            return 4
        case .sendTyping:
            return 5
        case .detailsFooter:
            return 6
        case .historyHeader:
            return 7
        case .saveDeleted:
            return 8
        case .saveEdits:
            return 9
        case .historyFooter:
            return 10
        }
    }

    static func <(lhs: PhantomSettingsEntry, rhs: PhantomSettingsEntry) -> Bool {
        return lhs.stableId < rhs.stableId
    }

    func item(presentationData: ItemListPresentationData, arguments: Any) -> ListViewItem {
        let arguments = arguments as! PhantomSettingsControllerArguments
        switch self {
        case let .ghostHeader(text), let .historyHeader(text):
            return ItemListSectionHeaderItem(presentationData: presentationData, text: text, sectionId: self.section)
        case let .ghostFooter(text), let .detailsFooter(text), let .historyFooter(text):
            return ItemListTextItem(presentationData: presentationData, text: .plain(text), sectionId: self.section)
        case let .ghostMode(title, value):
            return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: title, value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateGhostMode(value)
            })
        case let .sendRead(title, value):
            return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: title, value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateSendReadMessages(value)
            })
        case let .sendOnline(title, value):
            return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: title, value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateSendOnlinePackets(value)
            })
        case let .sendTyping(title, value):
            return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: title, value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateSendTyping(value)
            })
        case let .saveDeleted(title, value):
            return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: title, value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateSaveDeletedMessages(value)
            })
        case let .saveEdits(title, value):
            return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: title, value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateSaveEditsHistory(value)
            })
        }
    }
}

private func phantomSettingsEntries(strings: PhantomStrings, state: PhantomSettingsState) -> [PhantomSettingsEntry] {
    var entries: [PhantomSettingsEntry] = []
    entries.append(.ghostHeader(strings.ghostHeader))
    entries.append(.ghostMode(strings.ghostMode, state.ghostMode))
    entries.append(.ghostFooter(strings.ghostFooter))
    entries.append(.sendRead(strings.sendRead, state.sendReadMessages))
    entries.append(.sendOnline(strings.sendOnline, state.sendOnlinePackets))
    entries.append(.sendTyping(strings.sendTyping, state.sendTyping))
    entries.append(.detailsFooter(strings.detailsFooter))
    entries.append(.historyHeader(strings.historyHeader))
    entries.append(.saveDeleted(strings.saveDeleted, state.saveDeletedMessages))
    entries.append(.saveEdits(strings.saveEdits, state.saveEditsHistory))
    entries.append(.historyFooter(strings.historyFooter))
    return entries
}

public func phantomSettingsController(context: AccountContext) -> ViewController {
    let statePromise = ValuePromise(PhantomSettingsState.current(), ignoreRepeated: true)
    let refresh: () -> Void = {
        statePromise.set(PhantomSettingsState.current())
    }

    let arguments = PhantomSettingsControllerArguments(
        updateGhostMode: { value in
            PhantomSettings.ghostMode = value
            refresh()
        },
        updateSendReadMessages: { value in
            PhantomSettings.sendReadMessages = value
            refresh()
        },
        updateSendOnlinePackets: { value in
            PhantomSettings.sendOnlinePackets = value
            refresh()
        },
        updateSendTyping: { value in
            PhantomSettings.sendTyping = value
            refresh()
        },
        updateSaveDeletedMessages: { value in
            PhantomSettings.saveDeletedMessages = value
            refresh()
        },
        updateSaveEditsHistory: { value in
            PhantomSettings.saveEditsHistory = value
            refresh()
        }
    )

    let signal = combineLatest(queue: .mainQueue(),
        context.sharedContext.presentationData,
        statePromise.get()
    )
    |> map { presentationData, state -> (ItemListControllerState, (ItemListNodeState, Any)) in
        var presentationData = presentationData
        presentationData = presentationData.withUpdated(theme: presentationData.theme.withModalBlocksBackground())

        let strings = PhantomStrings(languageCode: presentationData.strings.primaryComponent.languageCode)

        let controllerState = ItemListControllerState(presentationData: ItemListPresentationData(presentationData), title: .text(strings.title), leftNavigationButton: nil, rightNavigationButton: nil, backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Back))
        let listState = ItemListNodeState(presentationData: ItemListPresentationData(presentationData), entries: phantomSettingsEntries(strings: strings, state: state), style: .blocks, animateChanges: true)

        return (controllerState, (listState, arguments))
    }

    let controller = ItemListController(context: context, state: signal)
    controller.navigationPresentation = .modal
    return controller
}
