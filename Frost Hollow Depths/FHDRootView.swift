import SwiftUI

enum FHDScreen: Equatable {
    case title
    case classSelect(daily: Bool)
    case game
    case summary
    case metaHub
    case daily
    case codex
    case achievements
    case history
    case settings
}

final class FHDNav: ObservableObject {
    @Published var screen: FHDScreen = .title
}

struct FHDRootView: View {
    @EnvironmentObject var store: FHDStore
    @StateObject private var nav = FHDNav()
    @StateObject private var engineHolder = FHDEngineHolder()

    var body: some View {
        GeometryReader { geo in
            let vw = min(geo.size.width, UIScreen.main.bounds.width)
            let vh = min(geo.size.height, UIScreen.main.bounds.height)
            ZStack {
                FHDTheme.abyss.edgesIgnoringSafeArea(.all)
                content
                    .frame(width: vw, height: vh)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .environmentObject(nav)
        .environmentObject(engineHolder)
    }

    @ViewBuilder private var content: some View {
        switch nav.screen {
        case .title:
            FHDTitleView()
        case .classSelect(let daily):
            FHDClassSelectView(daily: daily)
        case .game:
            if let eng = engineHolder.engine {
                FHDGameView(engine: eng)
            } else {
                FHDTitleView()
            }
        case .summary:
            if let eng = engineHolder.engine {
                FHDSummaryView(engine: eng)
            } else { FHDTitleView() }
        case .metaHub:
            FHDMetaHubView()
        case .daily:
            FHDDailyView()
        case .codex:
            FHDCodexView()
        case .achievements:
            FHDAchievementsView()
        case .history:
            FHDHistoryView()
        case .settings:
            FHDSettingsView()
        }
    }
}

// Holds the live engine so it survives screen switches.
final class FHDEngineHolder: ObservableObject {
    @Published var engine: FHDEngine? = nil

    func newGame(run: FHDRunState, store: FHDStore) {
        let e = FHDEngine(run: run, store: store)
        e.loadFloor(1, fromUp: true)
        engine = e
    }

    func resume(run: FHDRunState, store: FHDStore) {
        let e = FHDEngine(run: run, store: store)
        e.recomputeFOV()
        engine = e
    }

    func clear() { engine = nil }
}
