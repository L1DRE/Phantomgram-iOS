import Foundation
import SwiftSignalKit

/// Emits `PhantomSettings.hideStories` now and again whenever a Phantom setting changes.
private func phantomHideStoriesSignal() -> Signal<Bool, NoError> {
    return Signal<Bool, NoError> { subscriber in
        subscriber.putNext(PhantomSettings.hideStories)
        let observer = NotificationCenter.default.addObserver(forName: PhantomSettings.didChangeNotification, object: nil, queue: nil, using: { _ in
            subscriber.putNext(PhantomSettings.hideStories)
        })
        return ActionDisposable {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    |> distinctUntilChanged
}

/// Story subscriptions as the chat list should show them: empty while stories are hidden.
public func phantomFilteredStorySubscriptions(_ signal: Signal<EngineStorySubscriptions, NoError>) -> Signal<EngineStorySubscriptions, NoError> {
    return combineLatest(signal, phantomHideStoriesSignal())
    |> map { subscriptions, hidden -> EngineStorySubscriptions in
        if hidden {
            return EngineStorySubscriptions(accountItem: nil, items: [], hasMoreToken: nil)
        }
        return subscriptions
    }
}
