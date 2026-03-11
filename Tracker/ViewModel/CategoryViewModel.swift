import Foundation

enum CategoryViewModelState {
    case loading
    case loaded
    case empty
    case error(String)
    case categoryAdded(at: Int)        
    case categoryDeleted(at: Int)      
    case categoryUpdated(at: Int)      
    case selectionChanged(at: Int)
}

final class CategoryViewModel {
    
    // MARK: - Bindings
    var onStateChanged: ((CategoryViewModelState) -> Void)? 
    
    // MARK: - Properties
    private(set) var categories: [TrackerCategory] = [] {
        didSet {
            if categories.isEmpty {
                onStateChanged?(.empty)
            } else {
                onStateChanged?(.loaded)
            }
        }
    }
    
    private(set) var selectedCategory: TrackerCategory? {
        didSet {
            if let oldValue = oldValue,
               let oldIndex = categories.firstIndex(where: { $0.header == oldValue.header }) {
                onStateChanged?(.selectionChanged(at: oldIndex))
            }
            if let newValue = selectedCategory,
               let newIndex = categories.firstIndex(where: { $0.header == newValue.header }) {
                onStateChanged?(.selectionChanged(at: newIndex))
            }
        }
    }
    
    private let categoryStore: TrackerCategoryStore
    
    private var selectedCategoryTitle: String?
    
    // MARK: - Init
    init(categoryStore: TrackerCategoryStore = TrackerCategoryStore(), selectedCategoryTitle: String? = nil) {
            self.categoryStore = categoryStore
            self.selectedCategoryTitle = selectedCategoryTitle
        }
    
    // MARK: - Public Methods
    func loadCategories() {
        onStateChanged?(.loading)
        
        do {
            let loadedCategories = try categoryStore.fetchAllCategories()
            self.categories = loadedCategories
            
            if let selectedTitle = selectedCategoryTitle {
                self.selectedCategory = categories.first { $0.header == selectedTitle }
                print("✅ Установлена выбранная категория: \(selectedTitle)")
            }
            
        } catch {
            onStateChanged?(.error(error.localizedDescription))
        }
    }
    
    func createCategory(title: String) {
        
        if categories.contains(where: { $0.header.lowercased() == title.lowercased() }) {
                onStateChanged?(.error("Категория с таким названием уже существует"))
                return
            }
        
        do {
            let newCategory = try categoryStore.createCategory(title: title)
                categories.append(newCategory)
        } catch {
            onStateChanged?(.error(error.localizedDescription))
        }
    }
    
    func selectCategory(at index: Int) {
        guard index >= 0, index < categories.count else { return }
        selectedCategory = categories[index]
        onStateChanged?(.loaded)
    }
    
    // MARK: - Getters
    var numberOfCategories: Int {
        return categories.count
    }
    
    func category(at index: Int) -> TrackerCategory? {
        guard index >= 0, index < categories.count else { return nil }
        return categories[index]
    }
    
    func categoryTitle(at index: Int) -> String? {
        return category(at: index)?.header
    }
    
    func isCategorySelected(at index: Int) -> Bool {
        guard let category = category(at: index) else { return false }
        return selectedCategory?.header == category.header
    }
    
    func deleteCategory(at index: Int) {
        guard let category = category(at: index) else { return }
        
        do {
            try categoryStore.deleteCategory(title: category.header)
            categories.remove(at: index)
            
            if selectedCategory?.header == category.header {
                selectedCategory = nil
            }
        } catch {
            onStateChanged?(.error(error.localizedDescription))
        }
    }
    
    func updateCategory(oldTitle: String, newTitle: String) {
        
        if categories.contains(where: { $0.header.lowercased() == newTitle.lowercased() && $0.header.lowercased() != oldTitle.lowercased() }) {
                onStateChanged?(.error("Категория с таким названием уже существует"))
                return
            }
        
        do {
            try categoryStore.updateCategory(oldTitle: oldTitle, newTitle: newTitle)
            
            if let index = categories.firstIndex(where: { $0.header == oldTitle }) {
                let updatedCategory = TrackerCategory(
                    header: newTitle,
                    trackers: categories[index].trackers
                )
                categories[index] = updatedCategory
                
                if selectedCategory?.header == oldTitle {
                    selectedCategory = updatedCategory
                }
            }
        } catch {
            onStateChanged?(.error(error.localizedDescription))
        }
    }
    
    func setSelectedCategory(_ title: String) {
        self.selectedCategory = categories.first { $0.header == title }
    }
}
