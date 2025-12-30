//
//  TaskListViewModel.swift
//  TaskApp
//
//  Created by Francisco José García García on 15/10/25.
//
import Foundation
import Combine
import SwiftUI

@MainActor
class TaskListViewModel: ObservableObject {
    
    private let storageProvider: StorageProvider
    
    init(storageProvider: StorageProvider) {
        self.storageProvider = storageProvider
    }
    
    @Published var tasks: [Task] = []
    
    func loadTasks() async {
        do {
            tasks = try await storageProvider.loadTasks()
        } catch {
            print("Error loading tasks: \(error)")
        }
    }
    
    func addTask(task: Task) async{
        tasks.append(task)
        try? await storageProvider.saveTasks(tasks: tasks)
    }
    
    func removeTasks(atOffsets offsets: IndexSet) async{
        let tasksToDelete = offsets.map { tasks[$0] }
        
        // Notificar a los plugins ANTES de eliminar las tareas
        for task in tasksToDelete {
            await PluginRegistry.shared.notifyTaskWillBeDeleted(task)
        }
        
        // Eliminar las tareas
        tasks.remove(atOffsets: offsets)
        try? await storageProvider.saveTasks(tasks: tasks)
        
        // Notificar a los plugins DESPUÉS de eliminar las tareas
        for task in tasksToDelete {
            await PluginRegistry.shared.notifyTaskDidDelete(taskId: task.id)
        }
    }
    
    func toggleCompletion(task: Task) async {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index].isCompleted.toggle()
            try? await storageProvider.saveTasks(tasks: tasks)
        }
    }
    
    func saveTasks() async {
        try? await storageProvider.saveTasks(tasks: tasks)
    }
}
