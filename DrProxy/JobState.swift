//
//  JobState.swift
//  DrProxy
//
//  Created by Gareth Redman on 10/12/21.
//

import Foundation

@MainActor
class JobState: ObservableObject {
    enum Status {
        case stopped
        case running(Int)
        case error(Error)
        case stopping
        case starting

        static func from(pid: Int) -> Status {
            pid > 0 ? .running(pid) : .stopped
        }

        var isRunning: Bool {
            if case .running = self {
                return true
            } else {
                return false
            }
        }
        
        var description: String {
            switch self {
            case .stopped:
                return "Not running"
            case .running:
                return "Running"
            case .error:
                return "Error"
            case .stopping:
                return "Stopping"
            case .starting:
                return "Starting"
            }
        }
    }

    @Published private(set) var label: String
    @Published private(set) var status: Status = .stopped

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
            let newStatus = Status.from(pid: pid)
            if case .running = newStatus, case .stopping = status {
                // still running, but we are stopping, so ignore
            } else {
                status = newStatus
            }
        } catch {
            print("getPID failed with \(error)")
            status = .error(error)
        }
    }

    func loop() async {
        for await _ in Timer.stream(timeInterval: TimeInterval(0.5)) {
            await update()
        }
    }

    func stop() async {
        do {
            status = .stopping
            try await NSXPCConnection.launchService.stop(label: label)
        } catch {
            print("stop failed with \(error)")
        }
    }

    func start() async {
        do {
            status = .starting
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
