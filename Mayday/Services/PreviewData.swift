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
        return [
            AppNotification(
                id: UUID(uuidString: "10000000-0000-0000-0000-000000000001")!,
                topic: "Fire Alert",
                subject: "Пожарная тревога",
                body: "Обнаружено задымление на 12 этаже, корпус 9. Необходима немедленная эвакуация персонала.",
                metadata: ["Здание": "Корпус 9", "Этаж": "12", "Комната": "1A", "Датчик": "SM-4021"],
                status: .delivered,
                channel: .push,
                readAt: nil,
                createdAt: now.addingTimeInterval(-120),
                updatedAt: now.addingTimeInterval(-120)
            ),
            AppNotification(
                id: UUID(uuidString: "10000000-0000-0000-0000-000000000002")!,
                topic: "Security Alert",
                subject: "Нарушение периметра",
                body: "Зафиксировано несанкционированное проникновение через вход B2. Охрана уведомлена.",
                metadata: ["Зона": "B2", "Камера": "CAM-17"],
                status: .delivered,
                channel: .push,
                readAt: nil,
                createdAt: now.addingTimeInterval(-300),
                updatedAt: now.addingTimeInterval(-300)
            ),
            AppNotification(
                id: UUID(uuidString: "10000000-0000-0000-0000-000000000003")!,
                topic: "Fire Alert",
                subject: "Пожарная тревога",
                body: "Сработала пожарная сигнализация в серверной. Автоматическая система пожаротушения активирована.",
                metadata: ["Здание": "Корпус 9", "Этаж": "12", "Комната": "1A"],
                status: .read,
                channel: .push,
                readAt: now.addingTimeInterval(-3600),
                createdAt: now.addingTimeInterval(-7200),
                updatedAt: now.addingTimeInterval(-3600)
            ),
            AppNotification(
                id: UUID(uuidString: "10000000-0000-0000-0000-000000000004")!,
                topic: "Medical Emergency",
                subject: "Медицинская помощь",
                body: "Запрос экстренной медицинской помощи на 3 этаже, кабинет 312. Бригада скорой помощи вызвана.",
                metadata: ["Здание": "Корпус 9", "Этаж": "3", "Комната": "312"],
                status: .read,
                channel: .push,
                readAt: now.addingTimeInterval(-5400),
                createdAt: now.addingTimeInterval(-7200),
                updatedAt: now.addingTimeInterval(-5400)
            ),
            AppNotification(
                id: UUID(uuidString: "10000000-0000-0000-0000-000000000005")!,
                topic: "Water Leak",
                subject: "Затопление",
                body: "Обнаружена утечка воды в подвальном помещении. Аварийная служба на месте.",
                metadata: ["Здание": "Корпус 3", "Этаж": "B1"],
                status: .read,
                channel: .inApp,
                readAt: now.addingTimeInterval(-86400),
                createdAt: now.addingTimeInterval(-90000),
                updatedAt: now.addingTimeInterval(-86400)
            ),
            AppNotification(
                id: UUID(uuidString: "10000000-0000-0000-0000-000000000006")!,
                topic: "Security Alert",
                subject: "Тестирование системы",
                body: "Плановое тестирование системы оповещения. Действий не требуется.",
                metadata: nil,
                status: .read,
                channel: .inApp,
                readAt: now.addingTimeInterval(-172800),
                createdAt: now.addingTimeInterval(-180000),
                updatedAt: now.addingTimeInterval(-172800)
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
