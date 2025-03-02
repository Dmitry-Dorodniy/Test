import Foundation

/// Класс для загрузки отзывов.
final class ReviewsProvider {
    
    private let bundle: Bundle
    // Кэш для хранения уже загруженных данных
    private var cache: [Int: Data] = [:]
    // Флаг для отслеживания текущих загрузок
    private var isLoading: [Int: Bool] = [:]
    // Очередь для синхронизации доступа к кэшу
    private let queue = DispatchQueue(label: "com.app.reviews.cache")
    
    init(bundle: Bundle = .main) {
        self.bundle = bundle
    }
    
}

// MARK: - Internal

extension ReviewsProvider {
    
    typealias GetReviewsResult = Result<Data, GetReviewsError>
    
    enum GetReviewsError: Error {
        
        case badURL
        case badData(Error)
        
    }
    
    func getReviews(offset: Int = 0, completion: @escaping (GetReviewsResult) -> Void) {
        // Проверяем кэш перед запросом
        if let cachedData = queue.sync(execute: { cache[offset] }) {
            completion(.success(cachedData))
            
            // Предзагружаем следующую страницу
            prefetchNextPage(after: offset)
            return
        }
        
        // Проверяем, не загружаются ли уже данные для этого offset
        if queue.sync(execute: { isLoading[offset] ?? false }) {
            return
        }
        
        queue.sync { isLoading[offset] = true }
        
        guard let url = bundle.url(forResource: "getReviews.response", withExtension: "json") else {
            queue.sync { isLoading[offset] = false }
            return completion(.failure(.badURL))
        }
        
        // Симулируем сетевой запрос - не менять
        usleep(.random(in: 100_000...1_000_000))
        
        do {
            let data = try Data(contentsOf: url)
            // Сохраняем данные в кэш
            queue.sync {
                cache[offset] = data
                isLoading[offset] = false
            }
            
            completion(.success(data))
            
            
            // Предзагружаем следующую страницу
            prefetchNextPage(after: offset)
        } catch {
            queue.sync { isLoading[offset] = false }
            completion(.failure(.badData(error)))
        }
    }
    
    /// Метод предзагрузки следующей страницы отзывов.
    /// - Parameter offset: Смещение текущей страницы, после которой нужно загрузить следующую.
    private func prefetchNextPage(after offset: Int) {
        let nextOffset = offset + 20
        
        // Проверяем, нет ли уже данных в кэше или загрузки
        if queue.sync(execute: { cache[nextOffset] != nil || isLoading[nextOffset] == true }) {
            return
        }
        
        // Предзагружаем следующую страницу
        DispatchQueue.global(qos: .utility).async { [weak self] in
            self?.getReviews(offset: nextOffset) { _ in }
        }
    }
    
}
