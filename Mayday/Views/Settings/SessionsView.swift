import SwiftUI

struct SessionsView: View {
    var viewModel: SettingsViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                ForEach(viewModel.sessions) { session in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(session.userAgent)
                                .font(.body)
                                .lineLimit(1)
                            if session.isCurrent {
                                Text("current_session")
                                    .font(.caption)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.success.opacity(0.2))
                                    .foregroundStyle(.success)
                                    .cornerRadius(4)
                            }
                        }
                        Text(session.ipAddress)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("session_created \(session.createdAt.formatted(date: .abbreviated, time: .shortened))")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .swipeActions(edge: .trailing) {
                        if !session.isCurrent {
                            Button(role: .destructive) {
                                Task { await viewModel.deleteSession(session) }
                            } label: {
                                Label("delete_button", systemImage: "trash")
                            }
                        }
                    }
                }
            }
            .navigationTitle("active_sessions_title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("done_button") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    SessionsView(viewModel: SettingsViewModel())
}
