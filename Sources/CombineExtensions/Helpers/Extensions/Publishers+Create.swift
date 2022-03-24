//
//  Publishers.swift
//  
//
//  Created by Dmitry Savinov on 24.03.2022.
//

import Combine

// MARK: - Create

extension Publishers {

    class Create<Output, Failure: Swift.Error>: Publisher {

        // MARK: - Properties

        /// "Create" callback closure
        private let callback: (AnyPublisher<Output, Failure>.Subscriber) -> Cancellable

        // MARK: - Initializers

        /// Defaul initializer
        /// - Parameter callback: "Create" callback closure
        init(callback: @escaping (AnyPublisher<Output, Failure>.Subscriber) -> Cancellable) {
            self.callback = callback
        }

        // MARK: - Publisher

        /// Attaches the specified subscriber to this publisher.
        ///
        /// Implementations of ``Publisher`` must implement this method.
        ///
        /// The provided implementation of ``Publisher/subscribe(_:)-4u8kn``calls this method.
        ///
        /// - Parameter subscriber: The subscriber to attach to this ``Publisher``, after which it can receive values.
        func receive<S: Subscriber>(subscriber: S) where Failure == S.Failure, Output == S.Input {
            subscriber.receive(subscription: Subscription(callback: callback, downstream: subscriber))
        }
    }
}

extension Publishers.Create {

    class Subscription<Downstream: Subscriber>: Combine.Subscription
    where Output == Downstream.Input, Failure == Downstream.Failure {

        // MARK: - Properties

        /// Currently processing buffer. We use it to
        /// implement complete "Create" publisher logic
        private let buffer: DemandBuffer<Downstream>

        /// Current cancellable instance
        private var cancellable: Cancellable?

        // MARK: - Initializers

        /// Default initializer
        /// - Parameters:
        ///   - callback: "Create" callback closure
        ///   - downstream: downstream publisher instance
        init(
            callback: @escaping (AnyPublisher<Output, Failure>.Subscriber) -> Cancellable,
            downstream: Downstream
        ) {
            self.buffer = DemandBuffer(subscriber: downstream)
            self.cancellable = callback(
                .init(
                    send: { [weak self] in
                        _ = self?.buffer.buffer(value: $0)
                    },
                    complete: { [weak self] in
                        self?.buffer.complete(completion: $0)
                    }
                )
            )
        }

        // MARK: - Subscription

        func request(_ demand: Subscribers.Demand) {
            _ = self.buffer.demand(demand)
        }

        func cancel() {
            self.cancellable?.cancel()
        }
    }
}
