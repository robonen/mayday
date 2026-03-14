#if DEBUG
import Foundation
import ActivityKit

enum PreviewData {
    nonisolated(unsafe) static var isPreviewMode = false

    static let mockUser = UserResponse(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
        email: "demo@mayday.app",
        status: .active,
        metadata: nil,
        emailVerifiedAt: Date(),
        roles: ["user"],
        createdAt: Date().addingTimeInterval(-90 * 86400),
        updatedAt: Date()
    )

    static let mockNotifications: [AppNotification] = {
        let now = Date()
        let mockUserId = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        return [
            AppNotification(
                id: UUID(uuidString: "10000000-0000-0000-0000-000000000001")!,
                userId: mockUserId,
                scopeId: nil,
                channel: .apns,
                contentType: .plain,
                templateId: nil,
                subject: "Пожарная тревога",
                body: "Обнаружено задымление на 12 этаже, корпус 9. Необходима немедленная эвакуация персонала.",
                source: "Fire Alert",
                metadata: ["Здание": "Корпус 9", "Этаж": "12", "Комната": "1A", "Датчик": "SM-4021"],
                status: .sent,
                error: nil,
                attempts: 1,
                maxAttempts: 3,
                nextRetryAt: nil,
                sentAt: now.addingTimeInterval(-120),
                readAt: nil,
                createdAt: now.addingTimeInterval(-120)
            ),
            AppNotification(
                id: UUID(uuidString: "10000000-0000-0000-0000-000000000002")!,
                userId: mockUserId,
                scopeId: nil,
                channel: .apns,
                contentType: .plain,
                templateId: nil,
                subject: "Нарушение периметра",
                body: "Зафиксировано несанкционированное проникновение через вход B2. Охрана уведомлена.",
                source: "Security Alert",
                metadata: ["Зона": "B2", "Камера": "CAM-17"],
                status: .sent,
                error: nil,
                attempts: 1,
                maxAttempts: 3,
                nextRetryAt: nil,
                sentAt: now.addingTimeInterval(-300),
                readAt: nil,
                createdAt: now.addingTimeInterval(-300)
            ),
            AppNotification(
                id: UUID(uuidString: "10000000-0000-0000-0000-000000000003")!,
                userId: mockUserId,
                scopeId: nil,
                channel: .apns,
                contentType: .plain,
                templateId: nil,
                subject: "Пожарная тревога",
                body: "Сработала пожарная сигнализация в серверной. Автоматическая система пожаротушения активирована.",
                source: "Fire Alert",
                metadata: ["Здание": "Корпус 9", "Этаж": "12", "Комната": "1A"],
                status: .read,
                error: nil,
                attempts: 1,
                maxAttempts: 3,
                nextRetryAt: nil,
                sentAt: now.addingTimeInterval(-7200),
                readAt: now.addingTimeInterval(-3600),
                createdAt: now.addingTimeInterval(-7200)
            ),
            AppNotification(
                id: UUID(uuidString: "10000000-0000-0000-0000-000000000004")!,
                userId: mockUserId,
                scopeId: nil,
                channel: .apns,
                contentType: .plain,
                templateId: nil,
                subject: "Медицинская помощь",
                body: "Запрос экстренной медицинской помощи на 3 этаже, кабинет 312. Бригада скорой помощи вызвана.",
                source: "Medical Emergency",
                metadata: ["Здание": "Корпус 9", "Этаж": "3", "Комната": "312"],
                status: .read,
                error: nil,
                attempts: 1,
                maxAttempts: 3,
                nextRetryAt: nil,
                sentAt: now.addingTimeInterval(-7200),
                readAt: now.addingTimeInterval(-5400),
                createdAt: now.addingTimeInterval(-7200)
            ),
            AppNotification(
                id: UUID(uuidString: "10000000-0000-0000-0000-000000000005")!,
                userId: mockUserId,
                scopeId: nil,
                channel: .inApp,
                contentType: .plain,
                templateId: nil,
                subject: "Затопление",
                body: "Обнаружена утечка воды в подвальном помещении. Аварийная служба на месте.",
                source: "Water Leak",
                metadata: ["Здание": "Корпус 3", "Этаж": "B1"],
                status: .read,
                error: nil,
                attempts: 1,
                maxAttempts: 3,
                nextRetryAt: nil,
                sentAt: now.addingTimeInterval(-90000),
                readAt: now.addingTimeInterval(-86400),
                createdAt: now.addingTimeInterval(-90000)
            ),
            AppNotification(
                id: UUID(uuidString: "10000000-0000-0000-0000-000000000006")!,
                userId: mockUserId,
                scopeId: nil,
                channel: .inApp,
                contentType: .plain,
                templateId: nil,
                subject: "Тестирование системы",
                body: "Плановое тестирование системы оповещения. Действий не требуется.",
                source: "Security Alert",
                metadata: nil,
                status: .read,
                error: nil,
                attempts: 1,
                maxAttempts: 3,
                nextRetryAt: nil,
                sentAt: now.addingTimeInterval(-180000),
                readAt: now.addingTimeInterval(-172800),
                createdAt: now.addingTimeInterval(-180000)
            ),
        ]
    }()

    static let mockSessions: [SessionResponse] = {
        let now = Date()
        return [
            SessionResponse(
                id: UUID(uuidString: "20000000-0000-0000-0000-000000000001")!,
                userAgent: "Mayday/1.0 (iPhone; iOS 18.3)",
                ipAddress: "192.168.1.42",
                isCurrent: true,
                createdAt: now.addingTimeInterval(-3600),
                expiresAt: now.addingTimeInterval(7 * 86400)
            ),
            SessionResponse(
                id: UUID(uuidString: "20000000-0000-0000-0000-000000000002")!,
                userAgent: "Mayday/1.0 (iPad; iPadOS 18.3)",
                ipAddress: "192.168.1.100",
                isCurrent: false,
                createdAt: now.addingTimeInterval(-86400),
                expiresAt: now.addingTimeInterval(6 * 86400)
            ),
        ]
    }()

    static func startMockLiveActivity() async {
        // End any existing demo activities first
        for activity in Activity<AlertAttributes>.activities where activity.attributes.alertId == "demo-fire-alert" {
            let state = activity.content.state
            await activity.end(ActivityContent(state: state, staleDate: nil), dismissalPolicy: .immediate)
        }

        let attributes = AlertAttributes(
            topic: "Fire Alert",
            alertId: "demo-fire-alert",
            severity: .critical
        )
        let state = AlertAttributes.ContentState(
            title: "Пожарная тревога",
            value: "Корпус 9, этаж 12",
            status: .active,
            startedAt: Date().addingTimeInterval(-120),
            updatedAt: Date()
        )
        _ = try? Activity<AlertAttributes>.request(
            attributes: attributes,
            content: ActivityContent(state: state, staleDate: Date().addingTimeInterval(3600))
        )
    }

    static func stopMockLiveActivity() async {
        for activity in Activity<AlertAttributes>.activities where activity.attributes.alertId == "demo-fire-alert" {
            let resolvedState = AlertAttributes.ContentState(
                title: "Пожарная тревога",
                value: "Корпус 9, этаж 12",
                status: .resolved,
                startedAt: activity.content.state.startedAt,
                updatedAt: Date()
            )
            await activity.end(ActivityContent(state: resolvedState, staleDate: nil), dismissalPolicy: .immediate)
        }
    }
}
#endif
