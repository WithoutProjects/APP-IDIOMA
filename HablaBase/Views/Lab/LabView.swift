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
                             color: .sky, mascot: .pentagon, mascotColor: .sunshine, mood: .curious)
                    }
                    NavigationLink {
                        GamesView()
                    } label: {
                        door(title: "Jugar",
                             detail: Gloss(en: "Verb minigames for your level.", it: "Minigiochi di verbi per il tuo livello.", uk: "Мініігри з дієсловами для твого рівня.", de: "Verb-Minispiele für dein Niveau.", fr: "Des mini-jeux de verbes adaptés à ton niveau.", pt: "Minijogos de verbos para o seu nível.", zh: "适合你级别的动词小游戏。"),
                             color: .tangerine, mascot: .flower, mascotColor: .bubblegum, mood: .excited)
                    }
                }
                .padding(20)
            }
            .navigationTitle("Conjugation Lab")
        }
    }

    /// A bright card with a mascot peeking in from the corner.
    private func door(title: String, detail: Gloss, color: FunColor,
                      mascot: MascotShape, mascotColor: FunColor, mood: MascotMood) -> some View {
        let shape = RoundedRectangle(cornerRadius: 28, style: .continuous)
        return ZStack(alignment: .topLeading) {
            shape.fill(color.main)
            Mascot(shape: mascot, color: mascotColor.main, mood: mood, size: 130)
                .rotationEffect(.degrees(-12))
                .offset(x: 30, y: 30)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
            VStack(alignment: .leading, spacing: 12) {
                Text(title)
                    .font(.system(.title2, design: .rounded).weight(.heavy))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(Color.white.opacity(0.22)))
                Text(detail.text(store.language))
                    .font(.subheadline.weight(.medium))
                    .opacity(0.95)
                    .multilineTextAlignment(.leading)
            }
            .padding(22)
            .padding(.trailing, 100)
        }
        .foregroundStyle(color.ink)
        .frame(maxWidth: .infinity, minHeight: 160)
        .clipShape(shape)
        .background(shape.fill(color.deep).offset(y: 5))
        .padding(.bottom, 5)
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
