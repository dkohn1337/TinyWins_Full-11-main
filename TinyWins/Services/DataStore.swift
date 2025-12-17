import Foundation

/// Protocol for data persistence, allowing easy swapping of storage backends
protocol DataStoreProtocol {
    func load() throws -> AppData
    func save(_ data: AppData) throws
    func clear() throws
}

/// JSON-based file storage implementation
final class JSONDataStore: DataStoreProtocol {
    private let fileName = "kidpoints_data.json"
    private let fileManager = FileManager.default
    
    private var fileURL: URL? {
        guard let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            #if DEBUG
            print("Error: Could not access documents directory")
            #endif
            return nil
        }
        return documentsDirectory.appendingPathComponent(fileName)
    }
    
    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        return encoder
    }()
    
    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
    
    func load() throws -> AppData {
        guard let fileURL = fileURL else {
            throw NSError(domain: "DataStore", code: 1, userInfo: [NSLocalizedDescriptionKey: "Could not access documents directory"])
        }
        guard fileManager.fileExists(atPath: fileURL.path) else {
            // Return default data if file doesn't exist
            return AppData.empty
        }

        let data = try Data(contentsOf: fileURL)
        return try decoder.decode(AppData.self, from: data)
    }
    
    func save(_ appData: AppData) throws {
        guard let fileURL = fileURL else {
            throw NSError(domain: "DataStore", code: 1, userInfo: [NSLocalizedDescriptionKey: "Could not access documents directory"])
        }
        let data = try encoder.encode(appData)
        try data.write(to: fileURL, options: .atomic)
    }
    
    func clear() throws {
        guard let fileURL = fileURL else {
            throw NSError(domain: "DataStore", code: 1, userInfo: [NSLocalizedDescriptionKey: "Could not access documents directory"])
        }
        if fileManager.fileExists(atPath: fileURL.path) {
            try fileManager.removeItem(at: fileURL)
        }
    }
}

/// In-memory store for previews and testing
final class InMemoryDataStore: DataStoreProtocol {
    private var data: AppData = .empty
    
    init(initialData: AppData = .empty) {
        self.data = initialData
    }
    
    func load() throws -> AppData {
        return data
    }
    
    func save(_ data: AppData) throws {
        self.data = data
    }
    
    func clear() throws {
        self.data = .empty
    }
}
