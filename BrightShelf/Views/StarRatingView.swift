import SwiftUI

public struct StarRatingView: View {
    let maximumRating: Int
    @Binding var rating: Int
    let onRatingChanged: (Int) -> Void
    var starSize: CGFloat = 24
    var horizontalPadding: CGFloat = 10
    var verticalPadding: CGFloat = 10
    var spacing: CGFloat = 8
    
    public init(
        maximumRating: Int,
        rating: Binding<Int>,
        onRatingChanged: @escaping (Int) -> Void,
        starSize: CGFloat = 24,
        horizontalPadding: CGFloat = 10,
        verticalPadding: CGFloat = 10,
        spacing: CGFloat = 8
    ) {
        self.maximumRating = maximumRating
        self._rating = rating
        self.onRatingChanged = onRatingChanged
        self.starSize = starSize
        self.horizontalPadding = horizontalPadding
        self.verticalPadding = verticalPadding
        self.spacing = spacing
    }
    
    public var body: some View {
        HStack(spacing: spacing) {
            ForEach(1...maximumRating, id: \.self) { number in
                Image(systemName: number <= rating ? "star.fill" : "star")
                    .foregroundStyle(number <= rating ? .yellow : .gray)
                    .font(.system(size: starSize))
                    .onTapGesture {
                        rating = number
                        onRatingChanged(number)
                    }
            }
        }
        .padding(.horizontal, horizontalPadding)
        .padding(.vertical, verticalPadding)
        .help("Bewertung: Klicken oder Tasten 0-5 drücken")
    }
} 