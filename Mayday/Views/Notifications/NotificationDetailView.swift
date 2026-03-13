import SwiftUI

struct NotificationDetailView: View {
    let notification: AppNotification
    let viewModel: NotificationsViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(notification.topic)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(notification.subject)
                        .font(.title2.bold())
                }

                Divider()

                VStack(alignment: .leading, spacing: 8) {
                    Text("Подробности:")
                        .font(.headline)
                    Text(notification.body)
                        .font(.body)
                }

                if let metadata = notification.metadata, !metadata.isEmpty {
                    Divider()
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Метаданные:")
                            .font(.headline)
                        ForEach(metadata.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                            HStack {
                                Text(key).foregroundStyle(.secondary)
                                Spacer()
                                Text(value)
                            }
                            .font(.footnote)
                        }
                    }
                }

                Divider()

                VStack(alignment: .leading, spacing: 8) {
                    LabeledContent("Получено") {
                        Text(notification.createdAt.formatted(date: .abbreviated, time: .shortened))
                    }
                    LabeledContent("Статус") {
                        Text(notification.status.rawValue)
                    }
                    LabeledContent("Канал") {
                        Text(notification.channel.rawValue)
                    }
                }
                .font(.footnote)

                Spacer()
            }
            .padding()
        }
        .navigationTitle("Уведомление")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.markAsRead(notification)
        }
    }
}
