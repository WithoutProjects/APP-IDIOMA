import SwiftUI

/// The verb workshop. Two doors: review the tables, or play verb games for your level.
struct LabView: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    NavigationLink {
                        TablesView()
                    } label: {
                        door(title: "Repasar tablas",
                             detail: Gloss(en: "Your verb tables and the Lego bench.", it: "Le tue tabelle dei verbi e il banco Lego.", uk: "Твої таблиці дієслів і лего-майстерня."),
                             icon: "tablecells", color: Brick.stem.color)
                    }
                    NavigationLink {
                        GamesView()
                    } label: {
                        door(title: "Jugar",
                             detail: Gloss(en: "Verb minigames for your level.", it: "Minigiochi di verbi per il tuo livello.", uk: "Мініігри з дієсловами для твого рівня."),
                             icon: "gamecontroller.fill", color: Brick.ending.color)
                    }
                }
                .padding(20)
            }
            .navigationTitle("Conjugation Lab")
        }
    }

    private func door(title: String, detail: Gloss, icon: String, color: Color) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.largeTitle)
                .frame(width: 56)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.title2.bold())
                Text(detail.text(store.language)).font(.subheadline).opacity(0.9)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .accessibilityHidden(true)
        }
        .foregroundStyle(.white)
        .padding(24)
        .frame(maxWidth: .infinity, minHeight: 130)
        .background(RoundedRectangle(cornerRadius: 24, style: .continuous).fill(color.gradient))
        .accessibilityElement(children: .combine)
    }
}

/// "Jugar": the minigames that are ready, each opening at its point on the path.
struct GamesView: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        List(LabGame.built) { game in
            if store.isCompleted(game.unlockedBy) {
                NavigationLink {
                    PairsGameView()
                } label: {
                    row(game, status: nil)
                }
            } else {
                row(game, status: store.language.localized("Opens after \u{201C}\(unlockTitle(game))\u{201D}"))
                    .opacity(0.55)
            }
        }
        .navigationTitle("Jugar")
    }

    private func unlockTitle(_ game: LabGame) -> String {
        Curriculum.sharedPath.first { $0.id == game.unlockedBy }?.title ?? game.unlockedBy
    }

    private func row(_ game: LabGame, status: String?) -> some View {
        HStack(spacing: 14) {
            Image(systemName: game.icon)
                .font(.title2)
                .foregroundStyle(Brick.ending.color)
                .frame(width: 36)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(game.title).font(.headline)
                Text(game.gloss.text(store.language)).font(.subheadline).foregroundStyle(.secondary)
                if let status {
                    Label(status, systemImage: "lock.fill").font(.caption).foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 6)
        .accessibilityElement(children: .combine)
    }
}
