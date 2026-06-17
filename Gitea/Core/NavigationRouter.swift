import Combine
import SwiftUI

@MainActor
final class NavigationRouter: ObservableObject {
	@Published var homePath = NavigationPath()
	@Published var pendingTab: ContentTab?

	func navigate(to destination: SpotlightDestination) {
		if case .repo(let instanceURL, _, _) = destination {
			if let matchingInstance = InstanceManager.instances.first(where: { $0.baseURL.absoluteString == instanceURL }),
				matchingInstance.id != InstanceManager.selected?.id
			{
				InstanceManager.select(matchingInstance)
				Network.invalidate()
				SessionStore.shared.refresh()
			}
		}
		pendingTab = .home
		homePath.append(destination)
	}
}
