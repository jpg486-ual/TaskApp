import Foundation
import SwiftData

protocol DueDateStorageProvider {
    func loadTaskDueDate(for taskId: UUID) async throws -> TaskDueDate?
    func saveTaskDueDate(_ dueDate: TaskDueDate) async throws
    func deleteDueDates(for taskId: UUID) async throws
}

class DueDateSwiftDataStorageProvider: DueDateStorageProvider {
    private let context: ModelContext
    
    init() {
        guard let context = SwiftDataContext.shared else {
            fatalError("SwiftData context not initialized")
        }
        self.context = context
    }
    
    func loadTaskDueDate(for taskId: UUID) async throws -> TaskDueDate? {
        let descriptor = FetchDescriptor<TaskDueDate>(predicate: #Predicate { $0.taskUid == taskId })
        let dueDates = try context.fetch(descriptor)
        return dueDates.first
    }
    
    func saveTaskDueDate(_ dueDate: TaskDueDate) async throws {
        let existing = try await loadTaskDueDate(for: dueDate.taskUid)
        if existing == nil {
            context.insert(dueDate)
        }
        // If exists, it's already modified since it's the same object
        try context.save()
    }
    
    func deleteDueDates(for taskId: UUID) async throws {
        let descriptor = FetchDescriptor<TaskDueDate>(predicate: #Predicate { $0.taskUid == taskId })
        let dueDates = try context.fetch(descriptor)
        for dueDate in dueDates {
            context.delete(dueDate)
        }
        try context.save()
    }
    
}

class DueDateJSONStorageProvider: DueDateStorageProvider {
    private let fileURL: URL

    init(filename: String = "duedates.json") {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        print("Documents Directory: \(documentsDirectory.path)")
        self.fileURL = documentsDirectory.appendingPathComponent(filename)
    }
    
    func loadTaskDueDate(for taskId: UUID) async throws -> TaskDueDate? {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return nil }
        let data = try Data(contentsOf: fileURL)
        let dueDates = try JSONDecoder().decode([TaskDueDate].self, from: data)
        return dueDates.first(where: { $0.taskUid == taskId })
    }
    
    func saveTaskDueDate(_ dueDate: TaskDueDate) async throws {
        var dueDates: [TaskDueDate] = []
        if FileManager.default.fileExists(atPath: fileURL.path) {
            let data = try Data(contentsOf: fileURL)
            dueDates = (try? JSONDecoder().decode([TaskDueDate].self, from: data)) ?? []
        }
        if let index = dueDates.firstIndex(where: { $0.taskUid == dueDate.taskUid }) {
            dueDates[index] = dueDate
        } else {
            dueDates.append(dueDate)
        }
        let data = try JSONEncoder().encode(dueDates)
        try data.write(to: fileURL)
    }
    
    func deleteDueDates(for taskId: UUID) async throws {
        var dueDates: [TaskDueDate] = []
        if FileManager.default.fileExists(atPath: fileURL.path) {
            let data = try Data(contentsOf: fileURL)
            dueDates = (try? JSONDecoder().decode([TaskDueDate].self, from: data)) ?? []
        }
        let filtered = dueDates.filter { $0.taskUid != taskId }
        let data = try JSONEncoder().encode(filtered)
        try data.write(to: fileURL)
    }
}
