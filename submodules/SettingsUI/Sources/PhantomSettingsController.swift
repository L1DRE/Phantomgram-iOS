import Foundation
import UIKit
import Display
import SwiftSignalKit
import TelegramCore
import TelegramPresentationData
import ItemListUI
import PresentationDataUtils
import AccountContext

/// One switch on the screen, bound to one `PhantomSettings` flag.
private enum PhantomToggle: Int32 {
    case ghostMode
    case sendRead
    case sendOnline
    case sendTyping
    case sendStories
    case sendConsumed
    case markReadOnSend
    case saveDeleted
    case saveEdits
    case showSeconds
    case hideAds
    case showPeerId
    case hideStories
    case hidePhone
    case compactMenu
    case keepPhotos

    var value: Bool {
        switch self {
        case .ghostMode: return PhantomSettings.ghostMode
        case .sendRead: return PhantomSettings.sendReadMessages
        case .sendOnline: return PhantomSettings.sendOnlinePackets
        case .sendTyping: return PhantomSettings.sendTyping
        case .sendStories: return PhantomSettings.sendStoriesSeen
        case .sendConsumed: return PhantomSettings.sendContentConsumed
        case .markReadOnSend: return PhantomSettings.markReadOnSend
        case .saveDeleted: return PhantomSettings.saveDeletedMessages
        case .saveEdits: return PhantomSettings.saveEditsHistory
        case .showSeconds: return PhantomSettings.showMessageSeconds
        case .hideAds: return PhantomSettings.hideSponsoredMessages
        case .showPeerId: return PhantomSettings.showPeerId
        case .hideStories: return PhantomSettings.hideStories
        case .hidePhone: return PhantomSettings.hidePhoneNumber
        case .compactMenu: return PhantomSettings.compactSettingsMenu
        case .keepPhotos: return PhantomSettings.keepDisappearingPhotos
        }
    }

    func set(_ value: Bool) {
        switch self {
        case .ghostMode: PhantomSettings.ghostMode = value
        case .sendRead: PhantomSettings.sendReadMessages = value
        case .sendOnline: PhantomSettings.sendOnlinePackets = value
        case .sendTyping: PhantomSettings.sendTyping = value
        case .sendStories: PhantomSettings.sendStoriesSeen = value
        case .sendConsumed: PhantomSettings.sendContentConsumed = value
        case .markReadOnSend: PhantomSettings.markReadOnSend = value
        case .saveDeleted: PhantomSettings.saveDeletedMessages = value
        case .saveEdits: PhantomSettings.saveEditsHistory = value
        case .showSeconds: PhantomSettings.showMessageSeconds = value
        case .hideAds: PhantomSettings.hideSponsoredMessages = value
        case .showPeerId: PhantomSettings.showPeerId = value
        case .hideStories: PhantomSettings.hideStories = value
        case .hidePhone: PhantomSettings.hidePhoneNumber = value
        case .compactMenu: PhantomSettings.compactSettingsMenu = value
        case .keepPhotos: PhantomSettings.keepDisappearingPhotos = value
        }
    }
}

private let phantomIconPink: [UIColor] = [UIColor(rgb: 0xff7aa8), UIColor(rgb: 0xe0356f)]
private let phantomIconViolet: [UIColor] = [UIColor(rgb: 0xb07cff), UIColor(rgb: 0x7a3df0)]
private let phantomIconIndigo: [UIColor] = [UIColor(rgb: 0x7d8cff), UIColor(rgb: 0x4a55d6)]
private let phantomIconGraphite: [UIColor] = [UIColor(rgb: 0x5a5a66), UIColor(rgb: 0x2c2c34)]

private func phantomIcon(_ name: String, _ colors: [UIColor]) -> UIImage? {
    return renderSettingsIcon(name: "Item List/Icons/\(name)", backgroundColors: colors)
}

/// Rendered once: every icon is a gradient fill, a mask and a backdrop.
private let phantomToggleIcons: [PhantomToggle: UIImage] = {
    var icons: [PhantomToggle: UIImage] = [:]
    icons[.ghostMode] = PresentationResourcesSettings.phantom
    icons[.sendRead] = phantomIcon("View", phantomIconPink)
    icons[.sendOnline] = phantomIcon("Wifi", phantomIconPink)
    icons[.sendTyping] = phantomIcon("Chat", phantomIconPink)
    icons[.sendStories] = phantomIcon("Stories", phantomIconPink)
    icons[.sendConsumed] = phantomIcon("Notifications", phantomIconPink)
    icons[.markReadOnSend] = phantomIcon("Messages", phantomIconPink)
    icons[.saveDeleted] = phantomIcon("Delete", phantomIconViolet)
    icons[.saveEdits] = phantomIcon("File", phantomIconViolet)
    icons[.keepPhotos] = phantomIcon("Timer", phantomIconViolet)
    icons[.showSeconds] = phantomIcon("Clock", phantomIconIndigo)
    icons[.hideAds] = phantomIcon("Block", phantomIconIndigo)
    icons[.showPeerId] = phantomIcon("Profile", phantomIconIndigo)
    icons[.hideStories] = phantomIcon("Stories", phantomIconGraphite)
    icons[.hidePhone] = phantomIcon("ChangePhone", phantomIconGraphite)
    icons[.compactMenu] = phantomIcon("Settings", phantomIconGraphite)
    return icons
}()

/// The theme of the Phantomgram screen: the list's own, with the switches in the accent of the logo.
private func phantomSettingsTheme(_ theme: PresentationTheme) -> PresentationTheme {
    let theme = theme.withModalBlocksBackground()
    let list = theme.list.withUpdated(itemSwitchColors: theme.list.itemSwitchColors.withUpdated(contentColor: phantomAccentColor))
    return PresentationTheme(name: theme.name, index: theme.index, referenceTheme: theme.referenceTheme, overallDarkAppearance: theme.overallDarkAppearance, intro: theme.intro, passcode: theme.passcode, rootController: theme.rootController, list: list, chatList: theme.chatList, chat: theme.chat, actionSheet: theme.actionSheet, contextMenu: theme.contextMenu, inAppNotification: theme.inAppNotification, chart: theme.chart, preview: theme.preview)
}

private final class PhantomSettingsControllerArguments {
    let update: (PhantomToggle, Bool) -> Void

    init(update: @escaping (PhantomToggle, Bool) -> Void) {
        self.update = update
    }
}

private struct PhantomSettingsState: Equatable {
    var values: [Int32: Bool]

    static func current() -> PhantomSettingsState {
        var values: [Int32: Bool] = [:]
        var raw: Int32 = 0
        while let toggle = PhantomToggle(rawValue: raw) {
            values[raw] = toggle.value
            raw += 1
        }
        return PhantomSettingsState(values: values)
    }

    func value(_ toggle: PhantomToggle) -> Bool {
        return self.values[toggle.rawValue] ?? false
    }
}

/// The screen is not translated through PresentationStrings: Russian when the app language is
/// Russian, English otherwise.
private struct PhantomStrings {
    let isRussian: Bool

    init(languageCode: String) {
        self.isRussian = languageCode.hasPrefix("ru")
    }

    private func t(_ ru: String, _ en: String) -> String {
        return self.isRussian ? ru : en
    }

    var title: String { return "Phantomgram" }
    func versions(mod: String, telegram: String) -> String { return t("Версия мода \(mod)\nTelegram \(telegram)", "Mod version \(mod)\nTelegram \(telegram)") }
    func ghostStatus(active: Bool) -> String { return active ? t("Призрак активен", "Ghost mode is on") : t("Призрак выключен", "Ghost mode is off") }
    var appearanceHeader: String { return t("ОФОРМЛЕНИЕ", "APPEARANCE") }
    var appearanceFooter: String { return t("Компактное меню убирает из настроек Premium, звёзды, TON, Business и подарки.", "The compact menu removes Premium, Stars, TON, Business and gifts from Settings.") }
    var ghostHeader: String { return t("РЕЖИМ ПРИЗРАКА", "GHOST MODE") }
    var ghostFooter: String { return t("Другие не увидят, что вы в сети, печатаете, прочитали сообщения, посмотрели истории или прослушали голосовые.", "Others won't see that you are online, typing, or have read their messages, watched their stories or played their voice messages.") }
    var detailsFooter: String { return t("Прочитанное остаётся прочитанным только на этом устройстве. «Прочитать при отправке»: когда вы пишете в чат, он отмечается прочитанным, как в обычном Telegram.", "What you read stays read only on this device. Mark Read When Sending: writing in a chat marks it as read, as the official app would.") }
    var historyHeader: String { return t("ИСТОРИЯ СООБЩЕНИЙ", "MESSAGE HISTORY") }
    var historyFooter: String { return t("Удалённые сообщения помечаются значком 🗑 у времени. Старые версии текста — в меню сообщения, пункт «История правок». Сохранение исчезающих фото включайте до просмотра: оно действует только на входящие фото с таймером и на один просмотр. Всё хранится только на этом устройстве. Уже исчезнувшие фото не восстанавливаются; очистка кэша может удалить загруженные файлы.", "Deleted messages show 🗑 next to the time. Earlier versions of a text are in the message menu under Edit History. Enable Keep Disappearing Photos before viewing: it applies only to incoming timer and view-once photos. Everything stays on this device. Expired photos cannot be restored; clearing the cache may remove downloaded files.") }
    var interfaceHeader: String { return t("ИНТЕРФЕЙС", "INTERFACE") }
    var interfaceFooter: String { return t("Дата регистрации — оценка по ID, точность до нескольких месяцев. Нажатие на ID или дату копирует их. Аккаунтов можно добавить до 10.", "The registration date is estimated from the ID and can be off by a few months. Tap the ID or date to copy it. Up to 10 accounts can be added.") }

    func title(_ toggle: PhantomToggle) -> String {
        switch toggle {
        case .ghostMode: return t("Режим призрака", "Ghost Mode")
        case .sendRead: return t("Отправлять «прочитано»", "Send Read Receipts")
        case .sendOnline: return t("Отправлять «в сети»", "Send Online Status")
        case .sendTyping: return t("Отправлять «печатает»", "Send Typing Status")
        case .sendStories: return t("Отмечать истории просмотренными", "Mark Stories as Viewed")
        case .sendConsumed: return t("Отмечать голосовые прослушанными", "Mark Voice Messages as Played")
        case .markReadOnSend: return t("Прочитать при отправке", "Mark Read When Sending")
        case .saveDeleted: return t("Сохранять удалённые сообщения", "Save Deleted Messages")
        case .saveEdits: return t("Сохранять историю правок", "Save Edit History")
        case .showSeconds: return t("Секунды во времени сообщений", "Seconds in Message Time")
        case .hideAds: return t("Скрыть рекламу в каналах", "Hide Sponsored Messages")
        case .showPeerId: return t("ID и дата регистрации в профиле", "ID and Sign-Up Date in Profiles")
        case .hideStories: return t("Скрыть истории", "Hide Stories")
        case .hidePhone: return t("Скрыть номер в настройках", "Hide Phone Number in Settings")
        case .compactMenu: return t("Компактное меню настроек", "Compact Settings Menu")
        case .keepPhotos: return t("Сохранять исчезающие фото", "Keep Disappearing Photos")
        }
    }
}

private enum PhantomSettingsSection: Int32 {
    case logo
    case ghost
    case details
    case history
    case interface
    case appearance
}

private enum PhantomSettingsEntry: ItemListNodeEntry {
    case logo(Int32, String, String, String, Bool)
    case header(PhantomSettingsSection, Int32, String)
    case toggle(PhantomSettingsSection, Int32, PhantomToggle, String, Bool)
    case footer(PhantomSettingsSection, Int32, String)

    var section: ItemListSectionId {
        switch self {
        case .logo:
            return PhantomSettingsSection.logo.rawValue
        case let .header(section, _, _), let .toggle(section, _, _, _, _), let .footer(section, _, _):
            return section.rawValue
        }
    }

    var stableId: Int32 {
        switch self {
        case let .logo(id, _, _, _, _), let .header(_, id, _), let .toggle(_, id, _, _, _), let .footer(_, id, _):
            return id
        }
    }

    static func <(lhs: PhantomSettingsEntry, rhs: PhantomSettingsEntry) -> Bool {
        return lhs.stableId < rhs.stableId
    }

    func item(presentationData: ItemListPresentationData, arguments: Any) -> ListViewItem {
        let arguments = arguments as! PhantomSettingsControllerArguments
        switch self {
        case let .logo(_, title, subtitle, status, isStatusActive):
            return PhantomSettingsHeaderItem(theme: presentationData.theme, title: title, subtitle: subtitle, status: status, isStatusActive: isStatusActive, sectionId: self.section)
        case let .header(_, _, text):
            return ItemListSectionHeaderItem(presentationData: presentationData, text: text, sectionId: self.section)
        case let .footer(_, _, text):
            return ItemListTextItem(presentationData: presentationData, text: .plain(text), sectionId: self.section)
        case let .toggle(_, _, toggle, title, value):
            return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, icon: phantomToggleIcons[toggle], title: title, value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.update(toggle, value)
            })
        }
    }
}

private func phantomSettingsEntries(strings: PhantomStrings, state: PhantomSettingsState) -> [PhantomSettingsEntry] {
    var entries: [PhantomSettingsEntry] = []
    var nextId: Int32 = 0
    func header(_ section: PhantomSettingsSection, _ text: String) {
        entries.append(.header(section, nextId, text))
        nextId += 1
    }
    func toggle(_ section: PhantomSettingsSection, _ toggle: PhantomToggle) {
        entries.append(.toggle(section, nextId, toggle, strings.title(toggle), state.value(toggle)))
        nextId += 1
    }
    func footer(_ section: PhantomSettingsSection, _ text: String) {
        entries.append(.footer(section, nextId, text))
        nextId += 1
    }

    let isGhostActive = state.value(.ghostMode)
    entries.append(.logo(nextId, strings.title, strings.versions(mod: PhantomSettings.modVersion, telegram: phantomTelegramVersion()), strings.ghostStatus(active: isGhostActive), isGhostActive))
    nextId += 1

    header(.ghost, strings.ghostHeader)
    toggle(.ghost, .ghostMode)
    footer(.ghost, strings.ghostFooter)

    for item in [PhantomToggle.sendRead, .sendOnline, .sendTyping, .sendStories, .sendConsumed, .markReadOnSend] {
        toggle(.details, item)
    }
    footer(.details, strings.detailsFooter)

    header(.history, strings.historyHeader)
    toggle(.history, .saveDeleted)
    toggle(.history, .saveEdits)
    toggle(.history, .keepPhotos)
    footer(.history, strings.historyFooter)

    header(.interface, strings.interfaceHeader)
    toggle(.interface, .showSeconds)
    toggle(.interface, .hideAds)
    toggle(.interface, .showPeerId)
    footer(.interface, strings.interfaceFooter)

    header(.appearance, strings.appearanceHeader)
    toggle(.appearance, .hideStories)
    toggle(.appearance, .hidePhone)
    toggle(.appearance, .compactMenu)
    footer(.appearance, strings.appearanceFooter)
    return entries
}

/// The Telegram version this build is based on, with the build number.
private func phantomTelegramVersion() -> String {
    let info = Bundle.main.infoDictionary
    let version = info?["CFBundleShortVersionString"] as? String ?? "?"
    if let build = info?["CFBundleVersion"] as? String, !build.isEmpty {
        return "\(version) (\(build))"
    }
    return version
}

public func phantomSettingsController(context: AccountContext) -> ViewController {
    let statePromise = ValuePromise(PhantomSettingsState.current(), ignoreRepeated: true)

    let arguments = PhantomSettingsControllerArguments(update: { toggle, value in
        toggle.set(value)
        statePromise.set(PhantomSettingsState.current())
    })

    let signal = combineLatest(queue: .mainQueue(),
        context.sharedContext.presentationData,
        statePromise.get()
    )
    |> map { presentationData, state -> (ItemListControllerState, (ItemListNodeState, Any)) in
        var presentationData = presentationData
        presentationData = presentationData.withUpdated(theme: phantomSettingsTheme(presentationData.theme))

        let strings = PhantomStrings(languageCode: presentationData.strings.primaryComponent.languageCode)

        let controllerState = ItemListControllerState(presentationData: ItemListPresentationData(presentationData), title: .text(strings.title), leftNavigationButton: nil, rightNavigationButton: nil, backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Back))
        let listState = ItemListNodeState(presentationData: ItemListPresentationData(presentationData), entries: phantomSettingsEntries(strings: strings, state: state), style: .blocks, animateChanges: true)

        return (controllerState, (listState, arguments))
    }

    let controller = ItemListController(context: context, state: signal)
    controller.navigationPresentation = .modal
    return controller
}
