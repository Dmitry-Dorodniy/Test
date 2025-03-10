import UIKit

/// Класс, описывающий бизнес-логику экрана отзывов.
final class ReviewsViewModel: NSObject {

    /// Замыкание, вызываемое при изменении `state`.
    var onStateChange: ((State) -> Void)?

    private var state: State
    private let reviewsProvider: ReviewsProvider
    private let ratingRenderer: RatingRenderer
    private let decoder: JSONDecoder

    init(
        state: State = State(),
        reviewsProvider: ReviewsProvider = ReviewsProvider(),
        ratingRenderer: RatingRenderer = RatingRenderer(),
        decoder: JSONDecoder = JSONDecoder()
    ) {
        self.state = state
        self.reviewsProvider = reviewsProvider
        self.ratingRenderer = ratingRenderer
        self.decoder = decoder
    }

}

// MARK: - Internal

extension ReviewsViewModel {

    typealias State = ReviewsViewModelState

    /// Метод получения отзывов.
    func getReviews() {
        guard state.shouldLoad else { return }
        state.shouldLoad = false
        reviewsProvider.getReviews(offset: state.offset, completion: gotReviews)
    }

}

// MARK: - Private

private extension ReviewsViewModel {

    /// Метод обработки получения отзывов.
    func gotReviews(_ result: ReviewsProvider.GetReviewsResult) {
        do {
            let data = try result.get()
            let reviews = try decoder.decode(Reviews.self, from: data)

            state.reviewsCount = reviews.count
            state.items += reviews.items.map(makeReviewItem)
            state.offset += state.limit
            state.shouldLoad = state.offset < reviews.count
        } catch {
            state.shouldLoad = true
        }
        onStateChange?(state)
    }

    /// Метод, вызываемый при нажатии на кнопку "Показать полностью...".
    /// Снимает ограничение на количество строк текста отзыва (раскрывает текст).
    func showMoreReview(with id: UUID) {
        guard
            let index = state.items.firstIndex(where: { ($0 as? ReviewItem)?.id == id }),
            var item = state.items[index] as? ReviewItem
        else { return }
        item.maxLines = .zero
        state.items[index] = item
        onStateChange?(state)
    }


    /// Метод предварительной подготовки данных для ячеек.
    /// Вычисляет размеры текстовых полей в фоновом потоке для оптимизации отрисовки ячеек.
    func prefetchItems(at indexPaths: [IndexPath]) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            indexPaths.forEach { indexPath in
                guard 
                    let self = self,
                    indexPath.row < self.state.items.count,
                    let review = self.state.items[indexPath.row] as? ReviewItem 
                else { return }
                
                // Подготовка данных для ячейки
                _ = review.firstName.boundingRect(width: .greatestFiniteMagnitude)
                _ = review.lastName.boundingRect(width: .greatestFiniteMagnitude)
                _ = review.reviewText.boundingRect(width: .greatestFiniteMagnitude)
                _ = review.created.boundingRect(width: .greatestFiniteMagnitude)
            }
        }
    }

}

private extension ReviewsViewModel {

    typealias ReviewItem = ReviewCellConfig

    func makeReviewItem(_ review: Review) -> ReviewItem {
        print(review)

        let firstName = review.firstName.attributed(font: .username)
        let lastName = review.lastName.attributed(font: .username)
        let ratingImage = ratingRenderer.ratingImage(review.rating)
        let reviewText = review.text.attributed(font: .text)
        let created = review.created.attributed(font: .created, color: .created)
        let item = ReviewItem(
            firstName: firstName,
            lastName: lastName,
            ratingImage: ratingImage,
            reviewText: reviewText,
            created: created,
            onTapShowMore: showMoreReview
        )
        return item
    }

}

// MARK: - UITableViewDataSource

extension ReviewsViewModel: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        state.items.count + 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row < state.items.count {
            let config = state.items[indexPath.row]
            let cell = tableView.dequeueReusableCell(withIdentifier: config.reuseId, for: indexPath)
            config.update(cell: cell)
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: CountOfReviewsCell.reuseId, for: indexPath) as! CountOfReviewsCell
            cell.configure(with: state.reviewsCount)
            return cell
        }
    }

}

// MARK: - UITableViewDelegate

extension ReviewsViewModel: UITableViewDelegate {

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        indexPath.row < state.items.count ? state.items[indexPath.row].height(with: tableView.bounds.size) : 44
    }

    /// Метод дозапрашивает отзывы, если до конца списка отзывов осталось два с половиной экрана по высоте.
    func scrollViewWillEndDragging(
        _ scrollView: UIScrollView,
        withVelocity velocity: CGPoint,
        targetContentOffset: UnsafeMutablePointer<CGPoint>
    ) {
        if shouldLoadNextPage(scrollView: scrollView, targetOffsetY: targetContentOffset.pointee.y) {
            getReviews()
        }
    }

    private func shouldLoadNextPage(
        scrollView: UIScrollView,
        targetOffsetY: CGFloat,
        screensToLoadNextPage: Double = 2.5
    ) -> Bool {
        let viewHeight = scrollView.bounds.height
        let contentHeight = scrollView.contentSize.height
        let triggerDistance = viewHeight * screensToLoadNextPage
        let remainingDistance = contentHeight - viewHeight - targetOffsetY
        return remainingDistance <= triggerDistance
    }

}

extension ReviewsViewModel: UITableViewDataSourcePrefetching {

    func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        prefetchItems(at: indexPaths)
    }
}