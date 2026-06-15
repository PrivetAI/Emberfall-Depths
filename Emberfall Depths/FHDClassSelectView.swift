import SwiftUI

struct FHDClassSelectView: View {
    @EnvironmentObject var store: FHDStore
    @EnvironmentObject var nav: FHDNav
    @EnvironmentObject var holder: FHDEngineHolder
    var daily: Bool
    @State private var selected: FHDClassID = .ranger

    var body: some View {
        VStack(spacing: 0) {
            FHDHeaderBar(title: daily ? "Daily — Choose Class" : "Choose Your Class") {
                nav.screen = daily ? .daily : .title
            }
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(FHDClassID.allCases, id: \.self) { c in
                        classCard(c)
                    }
                    Button {
                        beginRun()
                    } label: {
                        Text("Descend as \(selected.name)")
                    }
                    .buttonStyle(FHDButtonStyle(tint: FHDTheme.torch))
                    .disabled(!store.isClassUnlocked(selected))
                    .opacity(store.isClassUnlocked(selected) ? 1 : 0.4)
                    .padding(.top, 6)
                }
                .padding(16)
                .fhdFit()
                .frame(maxWidth: .infinity)
            }
        }
    }

    private func beginRun() {
        let run = store.startRun(classID: selected, daily: daily)
        holder.newGame(run: run, store: store)
        store.saveRun(run)
        nav.screen = .game
    }

    @ViewBuilder private func classCard(_ c: FHDClassID) -> some View {
        let unlocked = store.isClassUnlocked(c)
        Button {
            if unlocked { selected = c }
        } label: {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    Circle().fill(classColor(c).opacity(0.18)).frame(width: 52, height: 52)
                    FHDGlyph(kind: classGlyph(c), size: 28, color: classColor(c))
                }
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(c.name).font(.system(size: 17, weight: .bold, design: .serif))
                            .foregroundColor(FHDTheme.ivory)
                        if !unlocked {
                            Text("LOCKED").font(.system(size: 9, weight: .heavy))
                                .foregroundColor(FHDTheme.danger)
                                .padding(.horizontal, 5).padding(.vertical, 2)
                                .background(RoundedRectangle(cornerRadius: 4).stroke(FHDTheme.danger, lineWidth: 1))
                        }
                    }
                    Text(c.tagline).font(.system(size: 12)).foregroundColor(FHDTheme.textDim)
                    Text(c.perk).font(.system(size: 11, weight: .medium, design: .serif))
                        .foregroundColor(classColor(c))
                        .padding(.top, 2)
                }
                Spacer()
            }
            .padding(13)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(selected == c ? classColor(c).opacity(0.12) : FHDTheme.panel)
                    .overlay(RoundedRectangle(cornerRadius: 14)
                        .stroke(selected == c ? classColor(c) : FHDTheme.stroke.opacity(0.5),
                                lineWidth: selected == c ? 2 : 1))
            )
        }
        .buttonStyle(.plain)
    }

    private func classColor(_ c: FHDClassID) -> Color {
        switch c {
        case .ranger: return FHDTheme.poison
        case .pyreKnight: return FHDTheme.torch
        case .frostWitch: return FHDTheme.iceCyan
        case .tinker: return FHDTheme.gold
        }
    }
    private func classGlyph(_ c: FHDClassID) -> FHDGlyph.Kind {
        switch c {
        case .ranger: return .boot
        case .pyreKnight: return .flame
        case .frostWitch: return .wand
        case .tinker: return .gear
        }
    }
}

// Reusable header bar with a back button.
struct FHDHeaderBar: View {
    var title: String
    var trailing: AnyView? = nil
    var onBack: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Button(action: onBack) {
                ZStack {
                    Circle().fill(FHDTheme.panelRaised).frame(width: 34, height: 34)
                    FHDChevronShape(dir: 2).frame(width: 16, height: 16).foregroundColor(FHDTheme.ivory)
                }
            }
            Text(title).font(.system(size: 17, weight: .bold, design: .serif))
                .foregroundColor(FHDTheme.ivory)
            Spacer()
            if let trailing = trailing { trailing }
        }
        .padding(.horizontal, 14).padding(.vertical, 10)
        .background(FHDTheme.deepBlue.edgesIgnoringSafeArea(.top))
    }
}
