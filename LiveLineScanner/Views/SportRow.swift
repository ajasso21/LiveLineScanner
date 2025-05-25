import SwiftUI

struct SportRow: View {
    let sport: Sport
    let events: [Event]
    let isExpanded: Bool
    let isFavorite: Bool
    let onEventTap: (Event) -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(sport.title)
                    .font(.headline)
                if isFavorite {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                        .imageScale(.small)
                }
                Spacer()
                Text("\(events.count) events")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
                    .rotationEffect(.degrees(isExpanded ? 90 : 0))
                    .animation(.spring(), value: isExpanded)
            }
            .padding(.vertical, 4)
            .contentShape(Rectangle())
            .background(Color.clear)
            
            if isExpanded {
                if events.isEmpty {
                    Text("No upcoming events")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.leading)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                } else {
                    ForEach(events) { event in
                        EventRow(event: event)
                            .onTapGesture {
                                onEventTap(event)
                            }
                            .transition(.opacity.combined(with: .slide))
                    }
                }
            }
        }
        .padding(.vertical, 4)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: events)
    }
}

struct EventRow: View {
    let event: Event
    @State private var isPressed = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\(event.homeTeam) vs \(event.awayTeam)")
                .font(.subheadline)
            HStack {
                Image(systemName: "clock")
                    .imageScale(.small)
                Text(event.commenceTime, style: .time)
                Text(event.commenceTime, style: .date)
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.secondary.opacity(isPressed ? 0.2 : 0.1))
                .animation(.easeOut(duration: 0.2), value: isPressed)
        )
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.2)) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation {
                    isPressed = false
                }
            }
        }
    }
}

extension View {
    func sportRowStyle(isExpanded: Bool) -> some View {
        self
            .contentShape(Rectangle())
            .listRowBackground(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isExpanded ? Color.secondary.opacity(0.1) : Color.clear)
                    .padding(.vertical, 2)
            )
    }
} 