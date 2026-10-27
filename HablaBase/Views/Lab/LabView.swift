import SwiftUI

/// The workshop: review the verb tables, play games for your level, swipe through words and
/// open the folder of saved ones.
struct LabView: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    ScreenHeader(eyebrow: Journey.currentLevel(store: store).map { Journey.caption($0, language: store.language) },
                                 title: "Conjugation Lab",
                                 subtitle: Self.intro.text(store.language))
                        .padding(.bottom, 8)
                    NavigationLink {
                        TablesView()
                    } label: {
                        LabCard(title: "Repasar tablas",
                                detail: Gloss(en: "Your verb tables and the Lego bench.", it: "Le tue tabelle dei verbi e il banco Lego.", uk: "Твої таблиці дієслів і лего-майстерня.", de: "Deine Verbtabellen und die Lego-Werkbank.", fr: "Tes tableaux de verbes et l'atelier Lego.", pt: "Suas tabelas de verbos e a bancada Lego.", zh: "你的动词变位表和积木台。"),
                                icon: "tablecells", language: store.language)
                    }
                    .buttonStyle(.plain)
                    NavigationLink {
                        GamesView()
                    } label: {
                        LabCard(title: "Jugar",
                                detail: Gloss(en: "Minigames for your level: verbs, words and sayings.", it: "Minigiochi per il tuo livello: verbi, parole e proverbi.", uk: "Мініігри для твого рівня: дієслова, слова й прислів'я.", de: "Minispiele für dein Niveau: Verben, Wörter und Sprichwörter.", fr: "Des mini-jeux adaptés à ton niveau : verbes, mots et proverbes.", pt: "Minijogos para o seu nível: verbos, palavras e ditados.", zh: "适合你级别的小游戏：动词、词汇和俗语。"),
                                icon: "gamecontroller.fill", language: store.language)
                    }
                    .buttonStyle(.plain)
                    NavigationLink {
                        WordFeedView()
                    } label: {
                        LabCard(title: WordFeedView.title,
                                detail: Self.feedDetail,
                                icon: "rectangle.stack.fill", language: store.language)
                    }
                    .buttonStyle(.plain)
                    NavigationLink {
                        FavoriteWordsView()
                    } label: {
                        LabCard(title: FavoriteWordsView.title,
                                detail: FavoriteWordsView.detail,
                                icon: "folder.fill", language: store.language,
                                count: store.favoriteWords.isEmpty ? nil : FavoriteWordsView.count(store.favoriteWords.count, language: store.language))
                    }
                    .buttonStyle(.plain)
                }
                .padding(20)
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    static let feedDetail = Gloss(en: "Swipe up through Spanish words and save your favourites.",
                                  it: "Scorri le parole spagnole e salva le tue preferite.",
                                  uk: "Гортай іспанські слова й зберігай улюблені.",
                                  de: "Wisch dich durch spanische Wörter und speichere deine Lieblinge.",
                                  fr: "Fais défiler des mots espagnols et garde tes préférés.",
                                  pt: "Deslize por palavras em espanhol e salve as suas favoritas.",
                                  zh: "向上滑动浏览西班牙语单词，收藏你喜欢的词。")
    static let intro = Gloss(en: "Practise outside the lessons: verbs, games and words.", it: "Allenati fuori dalle lezioni: verbi, giochi e parole.", uk: "Тренуйся поза уроками: дієслова, ігри та слова.", de: "Üben außerhalb der Lektionen: Verben, Spiele und Wörter.", fr: "Entraîne-toi en dehors des leçons : verbes, jeux et mots.", pt: "Pratique fora das lições: verbos, jogos e palavras.", zh: "在课程之外练习：动词、游戏和单词。")
}

/// A calm card: a tinted icon tile in the level's tone, the title and one line on what is inside.
struct LabCard: View {
    let title: String
    let detail: Gloss
    let icon: String
    let language: NativeLanguage
    var status: String?
    /// A quiet line under the detail, e.g. how many words are saved.
    var count: String?
    @Environment(\.tone) var tone

    var body: some View {
        HStack(spacing: 16) {
            ToneTile(size: 56) {
                Image(systemName: icon).font(.title2.weight(.semibold))
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.title3.weight(.semibold))
                Text(detail.text(language))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
                if let count {
                    Text(verbatim: count)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(tone.main)
                }
                if let status {
                    Label(status, systemImage: "lock.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 0)
            if status == nil {
                Image(systemName: "chevron.right")
                    .foregroundStyle(.tertiary)
                    .accessibilityHidden(true)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity)
        .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(Palette.card))
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}

/// "Jugar": the minigames that are ready, each opening at its point on the path.
struct GamesView: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                ForEach(LabGame.Kind.allCases, id: \.self) { kind in
                    let games = LabGame.built.filter { $0.kind == kind }
                    if !games.isEmpty {
                        VStack(alignment: .leading, spacing: 14) {
                            Text(verbatim: kind.title.text(store.language))
                                .font(.headline)
                                .foregroundStyle(.secondary)
                                .accessibilityAddTraits(.isHeader)
                            ForEach(games) { game in
                                if store.isCompleted(game.unlockedBy) {
                                    NavigationLink {
                                        destination(game)
                                    } label: {
                                        LabCard(title: game.title, detail: game.gloss, icon: game.icon, language: store.language)
                                    }
                                    .buttonStyle(.plain)
                                } else {
                                    LabCard(title: game.title, detail: game.gloss, icon: game.icon, language: store.language,
                                            status: store.language.localized("Opens after \u{201C}\(unlockTitle(game))\u{201D}"))
                                        .opacity(0.6)
                                }
                            }
                        }
                    }
                }
            }
            .padding(20)
        }
        .navigationTitle("Jugar")
    }

    @ViewBuilder
    private func destination(_ game: LabGame) -> some View {
        switch game.id {
        case LabGame.sprintId: SprintGameView()
        case LabGame.huntId: ErrorHuntView()
        case LabGame.voiceId: VoiceRecallView()
        case LabGame.wordMatchId: WordMatchView()
        case LabGame.orderId: SentenceOrderView()
        case LabGame.dictationId: DictationView()
        case LabGame.tensesId: TenseQuizView()
        case LabGame.timeMachineId: TimeMachineView()
        case LabGame.raceId: VerbRaceView()
        case LabGame.meaningId: MeaningQuizView()
        case LabGame.genderId: GenderGameView()
        case LabGame.oppositesId: OppositesView()
        case LabGame.sayingsId: SayingsView()
        default: PairsGameView()
        }
    }

    private func unlockTitle(_ game: LabGame) -> String {
        Curriculum.sharedPath.first { $0.id == game.unlockedBy }?.title ?? game.unlockedBy
    }
}
