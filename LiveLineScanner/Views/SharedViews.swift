import SwiftUI

struct PillSegmentControl<Label: View, T: Hashable>: View {
    @Binding var selection: T
    let options: [T]
    let label: (T) -> Label

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(options, id: \.self) { option in
                    let isSelected = option == selection
                    Button {
                        selection = option
                    } label: {
                        label(option)
                            .font(.subheadline.weight(.semibold))
                            .padding(.vertical, 6)
                            .padding(.horizontal, 12)
                            .background(isSelected ? Color.accentColor : Color(.secondarySystemBackground))
                            .foregroundColor(isSelected ? .white : .primary)
                            .clipShape(Capsule())
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}

struct HeaderRow: View {
    @State private var selectedTab: String = "MLB"
    let tabs = ["MLB", "Hits & HRs", "Knicks-Pacers", "Stars-Oilers", "WNBA"]

    var body: some View {
        PillSegmentControl(selection: $selectedTab, options: tabs) { tab in
            Text(tab)
        }
    }
}

struct CardRow<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.3), radius: 4, x: 0, y: 2)
            .padding(.horizontal)
            .padding(.vertical, 4)
    }
} 