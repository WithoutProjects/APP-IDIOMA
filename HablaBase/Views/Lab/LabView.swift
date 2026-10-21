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
                             detail: Gloss(en: "Your verb tables and the Lego bench.", it: "Le tue tabelle dei verbi e il banco Lego.", uk: "Твої таблиці дієслів і лего-майстерня.", de: "Deine Verbtabellen und die Lego-Werkbank.", fr: "Tes tableaux de verbes et l'atelier Lego.", pt: "Suas tabelas de verbos e a bancada Lego.", zh: "你的动词变位表和积木台。"),
                             icon: "tablecells", tone: .dustyBlue)
                    }
                    NavigationLink {
                        GamesView()
                    } label: {
                        door(title: "Jugar",
                             detail: Gloss(en: "Verb minigames for your level.", it: "Minigiochi di verbi per il tuo livello.", uk: "Мініігри з дієсловами для твого рівня.", de: "Verb-Minispiele für dein Niveau.", fr: "Des mini-jeux de verbes adaptés à ton niveau.", pt: "Minijogos de verbos para o seu nível.", zh: "适合你级别的动词小游戏。"),
                             icon: "gamecontroller.fill", tone: .terracotta)
                    }
                }
                .padding(20)
            }
            .navigationTitle("Conjugation Lab")
        }
    }

    /// A calm card: a tinted icon tile, the title and one line on what is inside.
    private func door(title: String, detail: Gloss, icon: String, tone: Tone) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2.weight(.semibold))
                .foregroundStyle(tone.main)
                .frame(width: 60, height: 60)
                .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(tone.soft))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.title3.weight(.semibold))
                Text(detail.text(store.language))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .foregroundStyle(.tertiary)
                .accessibilityHidden(true)
        }
        .foregroundStyle(.primary)
        .padding(18)
        .frame(maxWidth: .infinity)
        .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(Palette.card))
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
