import SwiftUI

struct GameRowView: View {
    let game: Game
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Teams
            HStack {
                Text(game.away)
                    .font(.headline)
                Spacer()
                Text("@")
                    .foregroundColor(.gray)
                Spacer()
                Text(game.home)
                    .font(.headline)
            }
            
            // Time
            Text(game.startTime, style: .time)
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    GameRowView(game: Game(
        id: "1",
        home: "Lakers",
        away: "Celtics",
        startTime: Date()
    ))
} 