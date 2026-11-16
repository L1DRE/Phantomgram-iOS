import Foundation
import UIKit
import Display
import TelegramCore
import TelegramPresentationData
import PresentationDataUtils
import AccountContext

extension ChatControllerImpl {
    /// Phantom: asks before a sticker or a GIF is sent, so a slip of the finger sends nothing.
    func phantomConfirmSend(isGif: Bool, send: @escaping () -> Void) {
        let presentationData = self.context.sharedContext.currentPresentationData.with { $0 }
        let isRussian = presentationData.strings.primaryComponent.languageCode.hasPrefix("ru")
        let text: String
        if isGif {
            text = isRussian ? "Отправить этот GIF?" : "Send this GIF?"
        } else {
            text = isRussian ? "Отправить этот стикер?" : "Send this sticker?"
        }
        self.present(textAlertController(context: self.context, title: nil, text: text, actions: [
            TextAlertAction(type: .genericAction, title: presentationData.strings.Common_Cancel, action: {}),
            TextAlertAction(type: .defaultAction, title: isRussian ? "Отправить" : "Send", action: {
                send()
            })
        ]), in: .window(.root))
    }
}
