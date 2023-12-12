//
// Created for LocalNotifications
// by Stewart Lynch on 2022-05-22
// Using Swift 5.0
//
// Follow me on Twitter: @StewartLynch
// Subscribe on YouTube: https://youTube.com/StewartLynch
//

import SwiftUI

struct NotificationsListView: View {
    @Environment(LocalNotificationManager.self) var lnManager
    @Environment(\.scenePhase) var scenePhase
    @State private var scheduleDate = Date()
    var body: some View {
        @Bindable var lnManager: LocalNotificationManager = lnManager
        NavigationView {
            VStack {
                if lnManager.isGranted {
                    GroupBox("Schedule") {
                        Button("Interval Notification") {
                            Task {
                                let localNotification = LocalNotification(identifier: UUID().uuidString,
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
                        .buttonStyle(.bordered)
                        GroupBox {
                            DatePicker("", selection: $scheduleDate)
                            Button("Calendar Notification") {
                                Task {
                                    let dateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: scheduleDate)
                                    let localNotification = LocalNotification(identifier: UUID().uuidString,
                                                                              title: "Calendar Notification",
                                                                              body: "Some Body",
                                                                              dateComponents: dateComponents,
                                                                              repeats: false)
                                    await lnManager.schedule(localNotification: localNotification)
                                }
                            }
                            .buttonStyle(.bordered)
                        }
                        Button("Promo Offer") {
                            Task {
                                let dateComponents = DateComponents(day: 1, hour: 10, minute: 0)
                                let localNotification = LocalNotification(identifier: UUID().uuidString,
                                                                          title: "Special Promotion",
                                                                          bundleImageName: "Stewart.png",
                                                                          userInfo: ["nextView" : NextView.promo.rawValue],
                                                                          body: "Take advantage of the monthly promotion",
                                                                          dateComponents: dateComponents,
                                                                          repeats: true)
                                await lnManager.schedule(localNotification: localNotification)
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                    .frame(width: 300)
                    List {
                        ForEach(lnManager.pendingRequests, id: \.identifier) { request in
                            VStack(alignment: .leading) {
                                Text(request.content.title)
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
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        lnManager.clearRequests()
                    } label: {
                        Image(systemName: "clear.fill")
                            .imageScale(.large)
                    }
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
