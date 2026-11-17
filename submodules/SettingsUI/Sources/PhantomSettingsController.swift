import Foundation
import UIKit
import Display
import SwiftSignalKit
import TelegramCore
import TelegramPresentationData
import ItemListUI
import PresentationDataUtils
import AccountContext
import TelegramUIPreferences

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
    case hideGift
    case hideContacts
    case confirmStickers
    case confirmGifs
    case stripTracking
    case noPreviews
    case confirmCalls
    case shakeGhost
    case bypassCopyProtection
    case previewVoice
    case noVoiceAutoplay
    case appSwitcherCover

    var value: Bool {
        switch self {
        case .ghostMode: return PhantomSettings.ghostMode
        case .sendRead: return !PhantomSettings.sendReadMessages
        case .sendOnline: return !PhantomSettings.sendOnlinePackets
        case .sendTyping: return !PhantomSettings.sendTyping
        case .sendStories: return !PhantomSettings.sendStoriesSeen
        case .sendConsumed: return !PhantomSettings.sendContentConsumed
        case .markReadOnSend: return PhantomSettings.markReadOnSend
        case .saveDeleted: return PhantomSettings.saveDeletedMessages
        case .saveEdits: return PhantomSettings.saveEditsHistory
        case .showSeconds: return PhantomSettings.showMessageSeconds
        case .hideAds: return PhantomSettings.hideSponsoredMessages
        case .showPeerId: return PhantomSettings.showPeerId
        case .hideStories: return PhantomSettings.hideStories
        case .hidePhone: return PhantomSettings.hidePhoneNumber
        case .compactMenu: return PhantomSettings.compactSettingsMenu
        case .bypassCopyProtection: return PhantomSettings.bypassCopyProtection
        case .keepPhotos: return PhantomSettings.keepDisappearingPhotos
        case .hideGift: return PhantomSettings.hideGiftButton
        case .hideContacts: return PhantomSettings.hideContactsTab
        case .confirmStickers: return PhantomSettings.confirmStickers
        case .confirmGifs: return PhantomSettings.confirmGifs
        case .stripTracking: return PhantomSettings.stripLinkTracking
        case .noPreviews: return PhantomSettings.disableLinkPreviews
        case .confirmCalls: return PhantomSettings.confirmCalls
        case .shakeGhost: return PhantomSettings.shakeTogglesGhost
        case .previewVoice: return PhantomSettings.previewVoiceMessages
        case .noVoiceAutoplay: return PhantomSettings.noVoiceAutoplay
        case .appSwitcherCover: return PhantomSettings.appSwitcherCover
        }
    }

    func set(_ value: Bool) {
        switch self {
        case .ghostMode: PhantomSettings.ghostMode = value
        case .sendRead: PhantomSettings.sendReadMessages = !value
        case .sendOnline: PhantomSettings.sendOnlinePackets = !value
        case .sendTyping: PhantomSettings.sendTyping = !value
        case .sendStories: PhantomSettings.sendStoriesSeen = !value
        case .sendConsumed: PhantomSettings.sendContentConsumed = !value
        case .markReadOnSend: PhantomSettings.markReadOnSend = value
        case .saveDeleted: PhantomSettings.saveDeletedMessages = value
        case .saveEdits: PhantomSettings.saveEditsHistory = value
        case .showSeconds: PhantomSettings.showMessageSeconds = value
        case .hideAds: PhantomSettings.hideSponsoredMessages = value
        case .showPeerId: PhantomSettings.showPeerId = value
        case .hideStories: PhantomSettings.hideStories = value
        case .hidePhone: PhantomSettings.hidePhoneNumber = value
        case .compactMenu: PhantomSettings.compactSettingsMenu = value
        case .bypassCopyProtection: PhantomSettings.bypassCopyProtection = value
        case .keepPhotos: PhantomSettings.keepDisappearingPhotos = value
        case .hideGift: PhantomSettings.hideGiftButton = value
        case .hideContacts: PhantomSettings.hideContactsTab = value
        case .confirmStickers: PhantomSettings.confirmStickers = value
        case .confirmGifs: PhantomSettings.confirmGifs = value
        case .stripTracking: PhantomSettings.stripLinkTracking = value
        case .noPreviews: PhantomSettings.disableLinkPreviews = value
        case .confirmCalls: PhantomSettings.confirmCalls = value
        case .shakeGhost: PhantomSettings.shakeTogglesGhost = value
        case .previewVoice: PhantomSettings.previewVoiceMessages = value
        case .noVoiceAutoplay: PhantomSettings.noVoiceAutoplay = value
        case .appSwitcherCover: PhantomSettings.appSwitcherCover = value
        }
    }
}

/// A row that does something when tapped.
private enum PhantomAction: Equatable {
    case checkUpdate
    case openUpdate(String)
    case applyTheme
    case openJournal
    case exportSettings
    case importSettings
}

private enum PhantomUpdateState: Equatable {
    case checking
    case upToDate
    case available(Int, String)
    case failed
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
    icons[.sendConsumed] = phantomIcon("Microphone", phantomIconPink)
    icons[.markReadOnSend] = phantomIcon("Checkbox", phantomIconPink)
    icons[.saveDeleted] = phantomIcon("Delete", phantomIconViolet)
    icons[.saveEdits] = phantomIcon("Brush", phantomIconViolet)
    icons[.bypassCopyProtection] = phantomIcon("File", phantomIconViolet)
    icons[.keepPhotos] = phantomIcon("Timer", phantomIconViolet)
    icons[.showSeconds] = phantomIcon("Clock", phantomIconIndigo)
    icons[.hideAds] = phantomIcon("NoAds", phantomIconIndigo)
    icons[.showPeerId] = phantomIcon("Profile", phantomIconIndigo)
    icons[.hideStories] = phantomIcon("Status", phantomIconGraphite)
    icons[.hidePhone] = phantomIcon("ChangePhone", phantomIconGraphite)
    icons[.compactMenu] = phantomIcon("Folder", phantomIconGraphite)
    icons[.hideGift] = phantomIcon("Gift", phantomIconIndigo)
    icons[.hideContacts] = phantomIcon("Member", phantomIconIndigo)
    icons[.confirmStickers] = phantomIcon("Sticker", phantomIconPink)
    icons[.confirmGifs] = phantomIcon("Gif", phantomIconPink)
    icons[.stripTracking] = phantomIcon("Link", phantomIconViolet)
    icons[.noPreviews] = phantomIcon("Photo", phantomIconViolet)
    icons[.confirmCalls] = phantomIcon("Phone", phantomIconPink)
    icons[.shakeGhost] = phantomIcon("Shuffle", phantomIconPink)
    icons[.previewVoice] = phantomIcon("Play", phantomIconPink)
    icons[.noVoiceAutoplay] = phantomIcon("Speed", phantomIconIndigo)
    icons[.appSwitcherCover] = phantomIcon("Privacy", phantomIconGraphite)
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
    let perform: (PhantomAction) -> Void

    init(update: @escaping (PhantomToggle, Bool) -> Void, perform: @escaping (PhantomAction) -> Void) {
        self.update = update
        self.perform = perform
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
    var installHeader: String { return t("УСТАНОВКА", "INSTALL") }
    var installFooter: String { return t("Бесплатный Apple ID подписывает приложение на 7 дней. Когда подпись истечёт, приложение перестанет запускаться — установите его заново через Sideloadly, чаты и настройки сохранятся.", "A free Apple ID signs the app for 7 days. When the signature expires the app stops launching: install it again with Sideloadly, your chats and settings stay.") }
    var signatureTitle: String { return t("Подпись", "Signature") }
    func signatureLabel(daysLeft: Int) -> String {
        if daysLeft < 0 {
            return t("истекла", "expired")
        } else if daysLeft == 0 {
            return t("истекает сегодня", "expires today")
        } else {
            return t("ещё \(daysLeft) дн.", "\(daysLeft) d. left")
        }
    }
    var updatesTitle: String { return t("Обновления", "Updates") }
    func updatesLabel(_ state: PhantomUpdateState) -> String {
        switch state {
        case .checking: return t("проверка…", "checking…")
        case .upToDate: return t("последняя версия", "up to date")
        case let .available(build, _): return t("сборка \(build)", "build \(build)")
        case .failed: return t("не удалось проверить", "check failed")
        }
    }
    var journalTitle: String { return t("Журнал удалённых", "Deleted Messages Journal") }
    var themeTitle: String { return t("Применить тему Phantom", "Apply the Phantom Theme") }
    var themeApplied: String { return t("Тема Phantom применена: тёмная, с розовым акцентом. Вернуть прежнюю можно в «Оформление».", "The Phantom theme is on: dark with a pink accent. You can switch back in Appearance.") }
    var sendingHeader: String { return t("ОТПРАВКА", "SENDING") }
    var sendingFooter: String { return t("Очистка ссылок убирает из отправляемых ссылок метки слежки (utm, fbclid, igshid и подобные).", "Link cleaning removes tracking tags (utm, fbclid, igshid and the like) from the links you send.") }
    var backupHeader: String { return t("РЕЗЕРВНАЯ КОПИЯ", "BACKUP") }
    var backupFooter: String { return t("Настройки мода копируются в буфер обмена как текст. Сохраните его в «Избранное», а после переустановки скопируйте и нажмите «Вставить настройки».", "The mod's settings are copied to the clipboard as text. Keep it in Saved Messages; after a reinstall copy it and tap Paste Settings.") }
    var exportTitle: String { return t("Скопировать настройки", "Copy Settings") }
    var importTitle: String { return t("Вставить настройки", "Paste Settings") }
    var exportDone: String { return t("Настройки скопированы в буфер обмена.", "The settings are in the clipboard.") }
    var importDone: String { return t("Настройки применены.", "The settings were applied.") }
    var importFailed: String { return t("В буфере обмена нет настроек Phantomgram.", "The clipboard holds no Phantomgram settings.") }
    var tabsFooterAddition: String { return t(" Скрытие вкладки «Контакты» применяется после перезапуска.", " Hiding the Contacts tab applies after a restart.") }
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
        case .sendRead: return t("Скрывать чтение", "Hide Read Receipts")
        case .sendOnline: return t("Скрывать «в сети»", "Hide Online Status")
        case .sendTyping: return t("Скрывать «печатает»", "Hide Typing")
        case .sendStories: return t("Скрывать просмотр историй", "Hide Story Views")
        case .sendConsumed: return t("Скрывать прослушивание", "Hide Voice Playback")
        case .markReadOnSend: return t("Читать при отправке", "Read When Sending")
        case .saveDeleted: return t("Сохранять удалённые", "Keep Deleted Messages")
        case .saveEdits: return t("Сохранять правки", "Keep Edit History")
        case .showSeconds: return t("Секунды в сообщениях", "Seconds in Time")
        case .hideAds: return t("Скрыть рекламу", "Hide Ads")
        case .showPeerId: return t("ID и дата в профиле", "ID and Date in Profiles")
        case .hideStories: return t("Скрыть истории", "Hide Stories")
        case .hidePhone: return t("Скрыть номер", "Hide Phone Number")
        case .compactMenu: return t("Компактное меню", "Compact Menu")
        case .bypassCopyProtection: return t("Обход запрета копирования", "Bypass Copy Protection")
        case .keepPhotos: return t("Сохранять TTL-фото", "Keep Timer Photos")
        case .hideGift: return t("Скрыть подарки", "Hide Gift Button")
        case .hideContacts: return t("Скрыть «Контакты»", "Hide Contacts Tab")
        case .confirmStickers: return t("Спрашивать: стикер", "Confirm Stickers")
        case .confirmGifs: return t("Спрашивать: GIF", "Confirm GIFs")
        case .stripTracking: return t("Чистить ссылки", "Clean Links")
        case .noPreviews: return t("Без превью ссылок", "No Link Previews")
        case .confirmCalls: return t("Спрашивать: звонок", "Confirm Calls")
        case .shakeGhost: return t("Призрак встряхиванием", "Shake for Ghost")
        case .previewVoice: return t("Прослушать ГС до отправки", "Preview Voice Messages")
        case .noVoiceAutoplay: return t("Не играть следующее ГС", "Don't Autoplay Next Voice")
        case .appSwitcherCover: return t("Скрывать в многозадачности", "Hide in App Switcher")
        }
    }
}

private enum PhantomSettingsSection: Int32 {
    case logo
    case install
    case ghost
    case details
    case history
    case sending
    case interface
    case appearance
    case backup
}

private enum PhantomSettingsEntry: ItemListNodeEntry {
    case logo(Int32, String, String, String, Bool)
    case header(PhantomSettingsSection, Int32, String)
    case toggle(PhantomSettingsSection, Int32, PhantomToggle, String, Bool)
    case footer(PhantomSettingsSection, Int32, String)
    /// A titled value; the Bool marks a value that needs attention, the action is optional.
    case info(PhantomSettingsSection, Int32, String, String, Bool, PhantomAction?)
    case action(PhantomSettingsSection, Int32, String, PhantomAction)

    var section: ItemListSectionId {
        switch self {
        case .logo:
            return PhantomSettingsSection.logo.rawValue
        case let .header(section, _, _), let .toggle(section, _, _, _, _), let .footer(section, _, _), let .info(section, _, _, _, _, _), let .action(section, _, _, _):
            return section.rawValue
        }
    }

    var stableId: Int32 {
        switch self {
        case let .logo(id, _, _, _, _), let .header(_, id, _), let .toggle(_, id, _, _, _), let .footer(_, id, _), let .info(_, id, _, _, _, _), let .action(_, id, _, _):
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
        case let .info(_, _, title, label, needsAttention, action):
            return ItemListDisclosureItem(presentationData: presentationData, systemStyle: .glass, title: title, label: label, labelStyle: needsAttention ? .coloredText(phantomAccentColor) : .text, sectionId: self.section, style: .blocks, disclosureStyle: action != nil ? .arrow : .none, action: action.flatMap { action -> (() -> Void) in
                return {
                    arguments.perform(action)
                }
            })
        case let .action(_, _, title, action):
            return ItemListActionItem(presentationData: presentationData, systemStyle: .glass, title: title, kind: .generic, alignment: .natural, sectionId: self.section, style: .blocks, action: {
                arguments.perform(action)
            })
        case let .toggle(_, _, toggle, title, value):
            return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, icon: phantomToggleIcons[toggle], title: title, value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.update(toggle, value)
            })
        }
    }
}

private func phantomSettingsEntries(strings: PhantomStrings, state: PhantomSettingsState, updateState: PhantomUpdateState) -> [PhantomSettingsEntry] {
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
    func info(_ section: PhantomSettingsSection, _ title: String, _ label: String, needsAttention: Bool = false, action: PhantomAction? = nil) {
        entries.append(.info(section, nextId, title, label, needsAttention, action))
        nextId += 1
    }
    func action(_ section: PhantomSettingsSection, _ title: String, _ action: PhantomAction) {
        entries.append(.action(section, nextId, title, action))
        nextId += 1
    }

    let isGhostActive = state.value(.ghostMode)
    entries.append(.logo(nextId, strings.title, strings.versions(mod: PhantomSettings.modVersion, telegram: phantomTelegramVersion()), strings.ghostStatus(active: isGhostActive), isGhostActive))
    nextId += 1

    header(.install, strings.installHeader)
    if let daysLeft = PhantomInstall.signatureDaysLeft {
        info(.install, strings.signatureTitle, strings.signatureLabel(daysLeft: daysLeft), needsAttention: daysLeft <= 1)
    }
    if case let .available(_, url) = updateState {
        info(.install, strings.updatesTitle, strings.updatesLabel(updateState), needsAttention: true, action: .openUpdate(url))
    } else {
        info(.install, strings.updatesTitle, strings.updatesLabel(updateState), action: .checkUpdate)
    }
    footer(.install, strings.installFooter)

    header(.ghost, strings.ghostHeader)
    toggle(.ghost, .ghostMode)
    toggle(.ghost, .shakeGhost)
    footer(.ghost, strings.ghostFooter)

    for item in [PhantomToggle.sendRead, .sendOnline, .sendTyping, .sendStories, .sendConsumed, .markReadOnSend] {
        toggle(.details, item)
    }
    footer(.details, strings.detailsFooter)

    header(.history, strings.historyHeader)
    toggle(.history, .saveDeleted)
    toggle(.history, .saveEdits)
    toggle(.history, .keepPhotos)
    toggle(.history, .bypassCopyProtection)
    info(.history, strings.journalTitle, "", action: .openJournal)
    footer(.history, strings.historyFooter)

    header(.sending, strings.sendingHeader)
    toggle(.sending, .confirmStickers)
    toggle(.sending, .confirmGifs)
    toggle(.sending, .confirmCalls)
    toggle(.sending, .previewVoice)
    toggle(.sending, .stripTracking)
    toggle(.sending, .noPreviews)
    footer(.sending, strings.sendingFooter)

    header(.interface, strings.interfaceHeader)
    toggle(.interface, .showSeconds)
    toggle(.interface, .hideAds)
    toggle(.interface, .showPeerId)
    toggle(.interface, .hideGift)
    toggle(.interface, .hideContacts)
    toggle(.interface, .noVoiceAutoplay)
    footer(.interface, strings.interfaceFooter + strings.tabsFooterAddition)

    header(.appearance, strings.appearanceHeader)
    toggle(.appearance, .hideStories)
    toggle(.appearance, .hidePhone)
    toggle(.appearance, .compactMenu)
    toggle(.appearance, .appSwitcherCover)
    action(.appearance, strings.themeTitle, .applyTheme)
    footer(.appearance, strings.appearanceFooter)

    header(.backup, strings.backupHeader)
    action(.backup, strings.exportTitle, .exportSettings)
    action(.backup, strings.importTitle, .importSettings)
    footer(.backup, strings.backupFooter)
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
    let updateStatePromise = ValuePromise(PhantomUpdateState.checking, ignoreRepeated: true)

    var pushControllerImpl: ((ViewController) -> Void)?
    var presentAlertImpl: ((String) -> Void)?

    let checkUpdate: () -> Void = {
        updateStatePromise.set(.checking)
        PhantomInstall.checkForUpdate(completion: { result in
            switch result {
            case .upToDate:
                updateStatePromise.set(.upToDate)
            case let .available(update):
                updateStatePromise.set(.available(update.buildNumber, update.url))
            case .failed:
                updateStatePromise.set(.failed)
            }
        })
    }

    let arguments = PhantomSettingsControllerArguments(update: { toggle, value in
        toggle.set(value)
        statePromise.set(PhantomSettingsState.current())
    }, perform: { action in
        let strings = PhantomStrings(languageCode: context.sharedContext.currentPresentationData.with { $0 }.strings.primaryComponent.languageCode)
        switch action {
        case .checkUpdate:
            checkUpdate()
        case let .openUpdate(url):
            context.sharedContext.applicationBindings.openUrl(url)
        case .applyTheme:
            let _ = (updatePresentationThemeSettingsInteractively(accountManager: context.sharedContext.accountManager, { current in
                var settings = current
                let theme = PresentationThemeReference.builtin(.night)
                settings.theme = theme
                settings.themeSpecificAccentColors[theme.index] = PresentationThemeAccentColor(index: -1, baseColor: .custom, accentColor: 0xffff5c93, bubbleColors: [0xffe0356f, 0xff9a4be0])
                settings.automaticThemeSwitchSetting.force = false
                return settings
            })
            |> deliverOnMainQueue).start(completed: {
                presentAlertImpl?(strings.themeApplied)
            })
        case .openJournal:
            pushControllerImpl?(phantomDeletedLogController(context: context))
        case .exportSettings:
            UIPasteboard.general.string = PhantomSettings.exportedSettings()
            presentAlertImpl?(strings.exportDone)
        case .importSettings:
            if let string = UIPasteboard.general.string, PhantomSettings.importSettings(string) {
                statePromise.set(PhantomSettingsState.current())
                presentAlertImpl?(strings.importDone)
            } else {
                presentAlertImpl?(strings.importFailed)
            }
        }
    })

    let signal = combineLatest(queue: .mainQueue(),
        context.sharedContext.presentationData,
        statePromise.get(),
        updateStatePromise.get()
    )
    |> map { presentationData, state, updateState -> (ItemListControllerState, (ItemListNodeState, Any)) in
        var presentationData = presentationData
        presentationData = presentationData.withUpdated(theme: phantomSettingsTheme(presentationData.theme))

        let strings = PhantomStrings(languageCode: presentationData.strings.primaryComponent.languageCode)

        let controllerState = ItemListControllerState(presentationData: ItemListPresentationData(presentationData), title: .text(strings.title), leftNavigationButton: nil, rightNavigationButton: nil, backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Back))
        let listState = ItemListNodeState(presentationData: ItemListPresentationData(presentationData), entries: phantomSettingsEntries(strings: strings, state: state, updateState: updateState), style: .blocks, animateChanges: true)

        return (controllerState, (listState, arguments))
    }

    let controller = ItemListController(context: context, state: signal)
    controller.navigationPresentation = .modal
    pushControllerImpl = { [weak controller] c in
        (controller?.navigationController as? NavigationController)?.pushViewController(c)
    }
    presentAlertImpl = { [weak controller] text in
        let presentationData = context.sharedContext.currentPresentationData.with { $0 }
        controller?.present(textAlertController(context: context, title: nil, text: text, actions: [TextAlertAction(type: .defaultAction, title: presentationData.strings.Common_OK, action: {})]), in: .window(.root))
    }
    checkUpdate()
    return controller
}
