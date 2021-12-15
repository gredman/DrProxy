//
//  JobState.swift
//  DrProxy
//
//  Created by Gareth Redman on 10/12/21.
//

import Foundation

@MainActor
class JobState: ObservableObject {
    @Published private(set) var label: String
    @Published private(set) var pid: Int? {
        didSet {
            isRunning = pid != nil
        }
    }
    @Published private(set) var isRunning = false

    init(label: String) {
        self.label = label
    }

    func setLabel(_ label: String) async {
        self.label = label
        await update()
    }

    func update() async {
        do {
            let pid = try await NSXPCConnection.launchService.getPID(label: label)
            self.pid = pid > 0 ? pid : nil
        } catch {
            print("getPID failed with \(error)")
            pid = nil
        }
    }

    func loop() async {
        for await _ in Timer.stream(timeInterval: TimeInterval(0.5)) {
            await update()
        }
    }

    func stop() async {
        do {
            try await NSXPCConnection.launchService.stop(label: label)
        } catch {
            print("stop failed with \(error)")
        }
    }

    func start() async {
        do {
            try await NSXPCConnection.launchService.start(label: label)
        } catch {
            print("start failed with \(error)")
        }
    }
}

extension Timer {
    static func stream(timeInterval: TimeInterval) -> AsyncStream<Date> {
        AsyncStream { cont in
            Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: true) { timer in
                cont.yield(Date())
            }
        }
    }
}