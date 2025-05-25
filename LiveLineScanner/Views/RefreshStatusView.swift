import SwiftUI

struct RefreshStatusView: View {
    @ObservedObject var refreshManager: BackgroundRefreshManager
    
    var body: some View {
        HStack(spacing: 8) {
            if refreshManager.isRefreshing {
                ProgressView()
                    .controlSize(.small)
                Text("Refreshing...")
                    .foregroundColor(.secondary)
                    .font(.caption)
            } else if let lastRefresh = refreshManager.lastRefreshTime {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                Text("Last updated: \(lastRefresh, style: .relative)")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 4)
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(8)
    }
}

#Preview {
    RefreshStatusView(refreshManager: BackgroundRefreshManager.shared)
} 