import SwiftUI

/// The AI Simulator lives here. Until the tutor is wired up, it shows what is coming and when it unlocks.
struct TalkView: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    card(icon: "flag.checkered",
                         title: "El mercado de San Miguel",
                         detail: Gloss(en: "Boss fight: buy dinner from Don Paco. Unlocks after Lesson 6.",
                                       it: "Boss: compra la cena da Don Paco. Si sblocca dopo la Lezione 6."))
                    card(icon: "bubble.left.and.bubble.right",
                         title: "Mi rutina",
                         detail: Gloss(en: "Free talk about your day with the AI tutor. Unlocks when you beat the boss.",
                                       it: "Conversazione libera sulla tua giornata con il tutor. Si sblocca battendo il boss."))
                }
                .padding(20)
            }
            .navigationTitle("Talk")
        }
    }

    private func card(icon: String, title: String, detail: Gloss) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon).font(.title2).foregroundStyle(Brick.rail.color)
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(title).font(.headline)
                    Image(systemName: "lock.fill").font(.caption).foregroundStyle(.secondary)
                }
                Text(detail.text(store.language)).font(.subheadline).foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 16).fill(Palette.card))
    }
}
