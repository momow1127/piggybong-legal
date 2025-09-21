import SwiftUI

// MARK: - Priority Drop Delegate for Fan Priority Management
struct PriorityDropDelegate: DropDelegate {
    let destinationIndex: Int
    @Binding var priorityItems: [(emoji: String, title: String, priority: String, color: Color)]
    let isReorderMode: Bool
    @Binding var draggedItemIndex: Int?
    
    func dropUpdated(info: DropInfo) -> DropProposal? {
        return DropProposal(operation: isReorderMode ? .move : .cancel)
    }
    
    func performDrop(info: DropInfo) -> Bool {
        guard isReorderMode else { return false }
        
        // Extract the source index from the drag data
        if let item = info.itemProviders(for: [.text]).first {
            item.loadObject(ofClass: NSString.self) { (sourceIndexString, error) in
                if let sourceIndexString = sourceIndexString as? String,
                   let sourceIndex = Int(sourceIndexString),
                   sourceIndex != destinationIndex {
                    
                    DispatchQueue.main.async {
                        // Perform the reorder with animation
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            let item = priorityItems.remove(at: sourceIndex)
                            priorityItems.insert(item, at: destinationIndex)
                        }
                        
                        // Reset drag state after successful drop
                        draggedItemIndex = nil
                    }
                }
            }
            return true
        }
        return false
    }
}