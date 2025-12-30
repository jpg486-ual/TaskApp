import Foundation
import Combine
import SwiftUI

@MainActor
class DueDateViewModel: ObservableObject {
    private let task: Task
    private let storageProvider: DueDateStorageProvider
    @Published var taskDueDate: TaskDueDate?
    
    init(task: Task, appConfig: AppConfig) {
        self.task = task
        switch appConfig.storageType {
        case .swiftData:
            self.storageProvider = DueDateSwiftDataStorageProvider()
        case .json:
            self.storageProvider = DueDateJSONStorageProvider()
        }
        _Concurrency.Task { await self.load() }
    }
    
    func load() async {
        do {
            if let loadedDueDate = try await storageProvider.loadTaskDueDate(for: task.id) {
                self.taskDueDate = loadedDueDate
            } else {
                taskDueDate = TaskDueDate(taskUid: task.id, dueDate: nil)
                await saveDueDate()
            }
        } catch {
            print("Error loading due date: \(error)")
        }
    }
    
    func saveDueDate() async {
        do {
            if let dueDateToSave = taskDueDate {
                try await storageProvider.saveTaskDueDate(dueDateToSave)
            }
        } catch {
            print("Error saving due date: \(error)")
        }
    }

    func toggleDueDate() {
        if taskDueDate?.dueDate != nil {
            taskDueDate?.dueDate = nil
        } else {
            taskDueDate?.dueDate = Date()
        }
        _Concurrency.Task { await saveDueDate() }
    }

    func setDueDate(_ date: Date?) {
        taskDueDate?.dueDate = date
        _Concurrency.Task { await saveDueDate() }
    }

    var hasDueDate: Bool {
        taskDueDate?.dueDate != nil
    }

    var dueDate: Date? {
        taskDueDate?.dueDate
    }
}
