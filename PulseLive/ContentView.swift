//
//  ContentView.swift
//  PulseLive
//
//  Created by Yogesh N Ramsorrun on 25/02/2025.
//

import SwiftUI

/*
 Potential pitfalls and edgecases
 - Large datasets will slow down responsiveness, especially if it has sticky headers and synchronisation of scrollviews
 - Loading of data needs to be considered especially if theres a huge dataset. Could use paging and not showing content until fully loaded, as well as maybe caching data so the user doesnt have to wait to load everytime they open the screen
 - State of position may be a consideration, especially if it's a big table and people would want to come back to it. This becomes an issue
 - Content filtering and sorting plays a big role as people will want to find the view and information.
 - Expected behaviour from tables: As mentioned sorting is important and people will expect to be able to tap a header and see the table sort itself i.e. tapping losses should allow to toggle from what it was previously to high-low and again to low-high
 - Different screen size(small phones and big ipads), orientation and font size(dynamic type) would need to be considered as it could look bad in certain situations so testing and working out good way to display it based on these factors is key.
 - Things like showing keyboard from the bottom could cause squashing or ugly ui and needs to be handled
 - Going back to text size or content in the cells, we need to consider whether we want to make these cells dynamically size based on if dynamic type is involved
 - Accessibility is a major concern as we would need to have proper conversation on how we would approach making adjustments for example: how would we screen read the information out or would tapping the right cell giving a the correct information.
 - As accessibility is a major hurdle due to screen read this would make UITesting tricky, so onus may fall to QA's.
 - This may not be that important but diagonal scrolling is not possible.
 - Localisation is another can of worms which would take significant effort due to either right-left languages, size of words or even characters. This can be minimised with dynamic cell dimensions but there can be edgecases from this edgecase
 */

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
                    SynchronisedHorizontalScrollView(
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
            SynchronisedHorizontalScrollView(
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
                    let _ = print(index)
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
struct SynchronisedHorizontalScrollView: UIViewRepresentable {
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

        scrollView.bounces = false

        content.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            content.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            content.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            content.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            content.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
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
        var parent: SynchronisedHorizontalScrollView
        var isUpdating = false

        init(_ parent: SynchronisedHorizontalScrollView) {
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
