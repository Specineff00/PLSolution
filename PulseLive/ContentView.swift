//
//  ContentView.swift
//  PulseLive
//
//  Created by Yogesh N Ramsorrun on 25/02/2025.
//

import SwiftUI

struct ContentView: View {
    @State private var horizontalOffset: CGFloat = 0

    // Consistent dimensions keeps alignment between header and content
    // This is only a simple version so things like dynamic type wouldnt work well
    private let cellWidth: CGFloat = 80
    private let cellHeight: CGFloat = 80
    private let cellSpacing: CGFloat = 0

    private let teams = Team.mocks
    private var clubNamesEnumeratedArray: [(offset: Int, element: String)] {
        Array(teams.map(\.club).enumerated())
    }

    var body: some View {
        VStack(alignment: .leading, spacing: cellSpacing) {
            header
            // Content
            // Ability to scroll down the list of content
            ScrollView {
                // Content stack
                // Each element is built with sticky content and non sticky content
                HStack(spacing: cellSpacing) { // content of sticky and non sticky side by side
                    positionAndClub
                    SynchronisedScrollView(
                        content: teamStats.toUIView(),
                        horizontalOffset: $horizontalOffset
                    )
                }
            }
        }
        .padding()
    }

    private var header: some View {
        HStack(spacing: cellSpacing) {
            // Headers
            // Sticky
            HStack(spacing: cellSpacing) {
                ForEach(ColumnHeader.allCases.filter { $0.isSticky }) { header in
                    Text(header.rawValue.capitalized)
                        .fontWeight(.bold)
                }
                .frame(width: cellWidth, height: cellHeight)
                .border(.gray)
            }
            // Non sticky
            SynchronisedScrollView(
                content:
                HStack(spacing: cellSpacing) {
                    ForEach(ColumnHeader.allCases.filter { !$0.isSticky }) { header in
                        Text(header.rawValue.capitalized)
                            .fontWeight(.bold)
                    }
                    .frame(width: cellWidth, height: cellHeight)
                    .border(.gray)
                }
                .toUIView(),
                horizontalOffset: $horizontalOffset
            )
            .frame(height: cellHeight)
        }
    }

    private var teamStats: some View {
        VStack(alignment: .leading, spacing: cellSpacing) { // Could be Lazy with more data
            ForEach(teams) { team in
                HStack(alignment: .center, spacing: cellSpacing) {
                    Group {
                        Text(team.matchesPlayed.description)
                        Text(team.wins.description)
                        Text(team.draws.description)
                        Text(team.losses.description)
                        Text(team.goalsScored.description)
                        Text(team.goalsAgainst.description)
                        Text(team.goalDifference.description)
                        Text(team.points.description)
                        Text(team.lastFive.first!.rawValue) // Fix to display to all five
                    }
                    .frame(width: cellWidth, height: cellHeight)
                    .border(.gray)
                }
            }
        }
        .fixedSize(horizontal: true, vertical: false)
        .background(.green)
    }

    private var positionAndClub: some View {
        VStack(alignment: .leading, spacing: cellSpacing) { // Could be Lazy with more data
            ForEach(clubNamesEnumeratedArray, id: \.element) { index, club in
                HStack(alignment: .center, spacing: cellSpacing) {
                    Group {
                        Text("\(index + 1)")
                        Text(club)
                            .background(.red)
                    }
                    .frame(width: cellWidth, height: cellHeight)
                    .border(.gray)
                }
            }
        }
        .fixedSize(horizontal: true, vertical: false)
        .background(.orange)
    }
}

#Preview {
    ContentView()
}

struct Team: Identifiable {
    let club: String
    let matchesPlayed: Int
    let wins: Int
    let draws: Int
    let losses: Int
    let goalsScored: Int
    let goalsAgainst: Int
    let goalDifference: Int
    let points: Int
    let lastFive: [MatchResult]

    enum MatchResult: String {
        case win
        case draw
        case loss
    }

    var id: String { club }
}

extension Team {
    static func generateRandomTeam() -> Team {
        .init(
            club: String(Int.random(in: 0 ... 50)), // Not safe but for testing purposes
            matchesPlayed: 4, // Originally had all generating random numbers but slowed down building
            wins: 5,
            draws: 6,
            losses: 7,
            goalsScored: 8,
            goalsAgainst: 9,
            goalDifference: 10,
            points: 11,
            lastFive: [.win, .win, .draw, .loss, .win]
        )
    }

    static var mocks: [Team] {
        [
            generateRandomTeam(),
            generateRandomTeam(),
            generateRandomTeam(),
            generateRandomTeam(),
            generateRandomTeam(),
            generateRandomTeam(),
            generateRandomTeam(),
        ]
    }
}

// This could be skipped if we used Mirror to reflect the property names of Team, but introduces complexities of logic to get and subsequent unit testing.
// Also, Team may have extra properties which we may not want to show i.e. id, Manager name or other non-relevant data. So this may be the better solution even though its verbose and more maintenance
enum ColumnHeader: String, CaseIterable, Identifiable {
    case position
    case club
    case matchesPlayed = "Matches played"
    case wins
    case draws
    case losses
    case goalsScored = "Goals scored"
    case goalsAgainst = "Goals against"
    case goalDifference = "Goal difference"
    case points
    case lastFive = "Last 5"

    var id: String { rawValue }

    var isSticky: Bool {
        switch self {
        case .position, .club:
            return true
        default:
            return false
        }
    }
}

// Due to lack of fine tuned control on ScrollView, falling back to UIScrollView is always a better solution than trying to wrangle and mess around with calculations from ScrollViewReader's proxy value
struct SynchronisedScrollView: UIViewRepresentable {
    let content: UIView
    @Binding var horizontalOffset: CGFloat
    let onScroll: ((CGFloat) -> Void)?

    init(content: UIView, horizontalOffset: Binding<CGFloat>, onScroll: ((CGFloat) -> Void)? = nil) {
        self.content = content
        _horizontalOffset = horizontalOffset
        self.onScroll = onScroll
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> UIScrollView {
        let scrollView = UIScrollView()
        scrollView.delegate = context.coordinator
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.addSubview(content)

        scrollView.alwaysBounceHorizontal = true
        scrollView.alwaysBounceVertical = false

        content.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            content.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            content.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            content.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            content.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),

            // This ensures the content view's height matches the scroll view
            content.heightAnchor.constraint(equalTo: scrollView.frameLayoutGuide.heightAnchor),
        ])

        return scrollView
    }

    func updateUIView(_ scrollView: UIScrollView, context _: Context) {
        scrollView.contentSize = content.bounds.size

        // Update scroll position if changed externally
        if scrollView.contentOffset.x != horizontalOffset {
            scrollView.contentOffset.x = horizontalOffset
        }
    }

    class Coordinator: NSObject, UIScrollViewDelegate {
        var parent: SynchronisedScrollView
        var isUpdating = false

        init(_ parent: SynchronisedScrollView) {
            self.parent = parent
        }

        func scrollViewDidScroll(_ scrollView: UIScrollView) {
            guard !isUpdating else { return }

            isUpdating = true
            // to prevent modifying state during view update
            DispatchQueue.main.async {
                self.parent.horizontalOffset = scrollView.contentOffset.x
                self.parent.onScroll?(scrollView.contentOffset.x)
                self.isUpdating = false
            }
        }
    }
}

extension View {
    func toUIView() -> UIView {
        let controller = UIHostingController(rootView: self)
        return controller.view
    }
}
