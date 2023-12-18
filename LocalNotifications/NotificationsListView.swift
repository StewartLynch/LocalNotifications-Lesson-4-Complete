//
// Created for LocalNotifications
// by Stewart Lynch on 2022-05-22
// Using Swift 5.0
//
// Follow me on Twitter: @StewartLynch
// Subscribe on YouTube: https://youTube.com/StewartLynch
//

import SwiftUI

enum DaysOfWeek: Int, CaseIterable, Identifiable {
    case sunday = 1, monday,tuesday, wednesday, thursday, friday, saturday
    var id: Self {
        return self
    }
    var dayLetter: String {
        switch self {
        case .sunday:
            "S"
        case .monday:
            "M"
        case .tuesday:
            "T"
        case .wednesday:
            "W"
        case .thursday:
            "T"
        case .friday:
            "F"
        case .saturday:
            "S"
        }
    }
    
    var dayName: String {
        switch self {
        case .sunday:
            "Sunday"
        case .monday:
            "Monday"
        case .tuesday:
            "Tuesday"
        case .wednesday:
            "Wednesday"
        case .thursday:
            "Thursday"
        case .friday:
            "Friday"
        case .saturday:
            "Saturday"
        }
    }
}

struct NotificationsListView: View {
    @Environment(LocalNotificationManager.self) var lnManager
    @Environment(\.scenePhase) var scenePhase
    @State private var scheduleDate = Date()
    @State private var scheduleTime = Date()
    @State private var scheduledDayOfWeek: Int?
    
    var body: some View {
        @Bindable var lnManager: LocalNotificationManager = lnManager
        NavigationStack {
            VStack {
                if lnManager.isGranted {
                    GroupBox("Schedule") {
                        Button("Interval Notification") {
                            Task {
                                let localNotification = LocalNotification(
                                    identifier: UUID().uuidString,
                                    categoryIdentifier: "snooze",
                                    title: "Some Title",
                                    subtitle: "This is a subtitle",
                                    bundleImageName:  "Stewart.png",
                                    userInfo: ["nextView" : NextView.renew.rawValue],
                                    body: "some body",
                                    timeInterval: 5,
                                    repeats: false)
                                await lnManager.schedule(localNotification: localNotification)
                            }
                        }
                        .buttonStyle(
                            .bordered
                        )
                        GroupBox {
                            DatePicker(
                                "",
                                selection: $scheduleDate
                            )
                            Button(
                                "Calendar Notification"
                            ) {
                                Task {
                                    let dateComponents = Calendar.current.dateComponents(
                                        [.year,
                                         .month,
                                         .day,
                                         .hour,
                                         .minute
                                        ],
                                        from: scheduleDate
                                    )
                                    let localNotification = LocalNotification(
                                        identifier: UUID().uuidString,
                                        title: "Calendar Notification",
                                        body: "Some Body",
                                        dateComponents: dateComponents,
                                        repeats: false
                                    )
                                    await lnManager.schedule(
                                        localNotification: localNotification
                                    )
                                }
                            }
                            .buttonStyle(
                                .bordered
                            )
                        }
                        Button("Promo Offer") {
                            Task {
                                let dateComponents = DateComponents(day: 11, hour: 18, minute: 56)
                                let localNotification = LocalNotification(
                                    identifier: UUID().uuidString,
                                    title: "Special Promotion",
                                    bundleImageName: "Stewart.png",
                                    userInfo: ["nextView" : NextView.promo.rawValue],
                                    body: "Take advantage of the monthly promotion",
                                    dateComponents: dateComponents,
                                    repeats: true
                                )
                                await lnManager.schedule(localNotification: localNotification)
                            }
                        }
                        .buttonStyle(.bordered)
                        
                        GroupBox {
                            DatePicker("Weekly Notification", selection: $scheduleDate, displayedComponents: [.hourAndMinute])
                            var dateComponents = Calendar.current.dateComponents([.hour, .minute], from: scheduleDate)
                            HStack {
                                ForEach(DaysOfWeek.allCases) { day in
                                    Button {
                                        scheduledDayOfWeek = day.rawValue
                                    } label: {
                                        Text(day.dayLetter)
                                            .foregroundStyle(.white)
                                    }
                                    .frame(width: 25)
                                    .background(RoundedRectangle(cornerRadius: 5.0))
//                                    .buttonStyle(.borderedProminent)
                                    .foregroundStyle(scheduledDayOfWeek == day.rawValue ? .red : .blue)
                                }
                            }
                            Button("Schedule") {
                                Task {
                                    if let scheduledDayOfWeek,
                                       let dayOfWeekName = DaysOfWeek(rawValue: scheduledDayOfWeek)?.dayName {
                                        dateComponents.weekday = scheduledDayOfWeek
                                        let localNotification = LocalNotification(
                                            identifier: UUID().uuidString,
                                            title: "Special Promotion",
                                            body: "Repeats every \(dayOfWeekName)",
                                            dateComponents: dateComponents,
                                            repeats: true
                                        )
                                        await lnManager.schedule(localNotification: localNotification)
                                    }
                                }
                            }
                            .buttonStyle(.bordered)
                            .disabled(scheduledDayOfWeek == nil)
                        }
                    }
                    .frame(width: 300)
                    List {
                        ForEach(lnManager.pendingRequests, id: \.identifier) { request in
                            VStack(alignment: .leading) {
                                Text(request.content.title)
                                //https://stackoverflow.com/questions/47127146/how-to-get-date-of-upcoming-notification-in-swift
                                let body = request.content.body
                                if !body.isEmpty {
                                    Text(body)
                                }
                                if let trigger = request.trigger as? UNCalendarNotificationTrigger,
                                   let nextTriggerDate = trigger.nextTriggerDate()  {
                                    Text(nextTriggerDate.formatted(date: .abbreviated, time: .shortened))
                                }
                                HStack {
                                    Text(request.identifier)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .swipeActions {
                                Button("Delete", role: .destructive) {
                                    lnManager.removeRequest(withIdentifier: request.identifier)
                                }
                            }
                        }
                    }
                } else {
                    Button("Enable Notifications") {
                        lnManager.openSettings()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .sheet(item: $lnManager.nextView) { $0 }
            .navigationTitle("Local Notifications")
            .toolbar {
                Button {
                    lnManager.clearRequests()
                } label: {
                    Image(systemName: "clear.fill")
                        .imageScale(.large)
                }
            }
        }
        .navigationViewStyle(.stack)
        .task {
            try? await lnManager.requestAuthorization()
        }
        .onChange(of: scenePhase) { _, newValue in
            if newValue == .active {
                Task {
                    await lnManager.getCurrentSettings()
                    await lnManager.getPendingRequests()
                }
            }
        }
    }
}

#Preview {
    NotificationsListView()
        .environment(LocalNotificationManager())
}
