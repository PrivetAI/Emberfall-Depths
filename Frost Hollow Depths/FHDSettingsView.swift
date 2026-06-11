import SwiftUI

// Settings: sound, haptics, reset (with confirm), privacy policy (WebPanel sheet).
struct FHDSettingsView: View {
    @EnvironmentObject var store: FHDStore
    @EnvironmentObject var nav: FHDNav
    @State private var showPrivacy = false
    @State private var confirmReset = false

    var body: some View {
        VStack(spacing: 0) {
            FHDHeaderBar(title: "Settings") { nav.screen = .title }
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    sectionHeader("GENERAL")
                    toggleRow(title: "Sound Effects",
                              subtitle: "Combat and interface feedback.",
                              glyph: .star, isOn: store.soundOn) {
                        store.soundOn.toggle()
                        store.saveMeta()
                    }
                    toggleRow(title: "Haptics",
                              subtitle: "Gentle taps on hits and pickups.",
                              glyph: .heart, isOn: store.hapticsOn) {
                        store.hapticsOn.toggle()
                        store.saveMeta()
                    }

                    sectionHeader("HELP")
                    actionRow(title: "Replay Tutorial",
                              subtitle: "Show the onboarding again next descent.",
                              glyph: .eye, tint: FHDTheme.frost) {
                        store.onboardingDone = false
                        store.saveMeta()
                    }

                    sectionHeader("ABOUT")
                    actionRow(title: "Privacy Policy",
                              subtitle: "How Frost Hollow Depths handles your data.",
                              glyph: .scroll, tint: FHDTheme.frost) {
                        showPrivacy = true
                    }

                    sectionHeader("DANGER")
                    actionRow(title: "Reset All Progress",
                              subtitle: "Erase shards, unlocks, awards, codex and history.",
                              glyph: .cross, tint: FHDTheme.danger) {
                        confirmReset = true
                    }

                    Text("Frost Hollow Depths 1.0")
                        .font(.system(size: 11))
                        .foregroundColor(FHDTheme.stroke)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 14)
                    Spacer(minLength: 24)
                }
                .padding(16)
                .fhdFit()
                .frame(maxWidth: .infinity)
            }
        }
        .sheet(isPresented: $showPrivacy) {
            FrostHollowWebPanel(urlString: "https://example.com")
                .edgesIgnoringSafeArea(.bottom)
                .background(Color.black.ignoresSafeArea())
        }
        .alert(isPresented: $confirmReset) {
            Alert(
                title: Text("Reset All Progress?"),
                message: Text("This permanently erases your Frost Shards, unlocks, achievements, codex, history and any run in progress."),
                primaryButton: .destructive(Text("Reset")) {
                    store.resetAll()
                },
                secondaryButton: .cancel()
            )
        }
    }

    private func sectionHeader(_ t: String) -> some View {
        Text(t)
            .font(.system(size: 11, weight: .heavy)).tracking(1.5)
            .foregroundColor(FHDTheme.frost)
            .padding(.top, 8)
    }

    private func toggleRow(title: String, subtitle: String, glyph: FHDGlyph.Kind,
                           isOn: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 11) {
                FHDGlyph(kind: glyph, size: 19, color: isOn ? FHDTheme.torch : FHDTheme.stroke)
                    .frame(width: 28)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 14, weight: .bold, design: .serif))
                        .foregroundColor(FHDTheme.ivory)
                    Text(subtitle).font(.system(size: 10)).foregroundColor(FHDTheme.textDim)
                }
                Spacer()
                // custom toggle pill
                ZStack(alignment: isOn ? .trailing : .leading) {
                    Capsule()
                        .fill(isOn ? FHDTheme.torch.opacity(0.85) : FHDTheme.panelRaised)
                        .frame(width: 46, height: 26)
                        .overlay(Capsule().stroke(FHDTheme.stroke.opacity(0.6), lineWidth: 1))
                    Circle()
                        .fill(FHDTheme.ivory)
                        .frame(width: 20, height: 20)
                        .padding(3)
                }
                .animation(.easeInOut(duration: 0.15), value: isOn)
            }
            .padding(11)
            .fhdCard()
        }
        .buttonStyle(.plain)
    }

    private func actionRow(title: String, subtitle: String, glyph: FHDGlyph.Kind,
                           tint: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 11) {
                FHDGlyph(kind: glyph, size: 19, color: tint)
                    .frame(width: 28)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 14, weight: .bold, design: .serif))
                        .foregroundColor(tint == FHDTheme.danger ? FHDTheme.danger : FHDTheme.ivory)
                    Text(subtitle).font(.system(size: 10)).foregroundColor(FHDTheme.textDim)
                }
                Spacer()
                FHDChevronShape(dir: 3)
                    .frame(width: 12, height: 12)
                    .foregroundColor(FHDTheme.stroke)
            }
            .padding(11)
            .fhdCard()
        }
        .buttonStyle(.plain)
    }
}
