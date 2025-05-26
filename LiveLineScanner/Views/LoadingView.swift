import SwiftUI

struct LoadingView: View {
    var body: some View {
        VStack {
            ProgressView()
                .progressViewStyle(.circular)
                .tint(.white)
            Text("Loading schedule...")
                .foregroundColor(.gray)
                .padding(.top)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    LoadingView()
} 