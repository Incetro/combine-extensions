//
//  DemandBuffer.swift
//  
//
//  Created by Dmitry Savinov on 24.03.2022.
//

import Combine
import Darwin

// MARK: - DemandBuffer

final class DemandBuffer<S: Subscriber> {

    // MARK: - Demand

    struct Demand {

        /// Processed demand
        var processed: Subscribers.Demand = .none

        /// Requested demand
        var requested: Subscribers.Demand = .none

        /// Sent demand
        var sent: Subscribers.Demand = .none
    }

    // MARK: - Properties

    /// Current buffer sequence
    private var buffer = [S.Input]()

    /// Subscriber instance
    private let subscriber: S

    /// Completion result
    private var completion: Subscribers.Completion<S.Failure>?

    /// Current state
    private var demandState = Demand()

    /// Locker instance
    private let lock: os_unfair_lock_t

    // MARK: - Initializers

    /// Default initializer
    /// - Parameter subscriber: subscriber instance
    init(subscriber: S) {
        self.subscriber = subscriber
        self.lock = os_unfair_lock_t.allocate(capacity: 1)
        self.lock.initialize(to: os_unfair_lock())
    }

    deinit {
        lock.deinitialize(count: 1)
        lock.deallocate()
    }

    // MARK: - Useful

    /// Buffer the given value
    /// - Parameter value: some input value
    /// - Returns: subscribers demand
    func buffer(value: S.Input) -> Subscribers.Demand {
        precondition(self.completion == nil, "How could a completed publisher sent values?! Beats me 🤷‍♂️")
        switch demandState.requested {
        case .unlimited:
            return subscriber.receive(value)
        default:
            buffer.append(value)
            return flush()
        }
    }

    /// Completes current work
    /// - Parameter completion: completion type
    func complete(completion: Subscribers.Completion<S.Failure>) {
        precondition(self.completion == nil, "Completion have already occurred, which is quite awkward 🥺")
        self.completion = completion
        _ = flush()
    }

    /// Return a new demand using the given demand
    /// - Parameter demand: input demand
    /// - Returns: a new demand using the given demand
    func demand(_ demand: Subscribers.Demand) -> Subscribers.Demand {
        flush(adding: demand)
    }

    // MARK: - Private

    private func flush(adding newDemand: Subscribers.Demand? = nil) -> Subscribers.Demand {
        lock.sync {
            if let newDemand = newDemand {
                demandState.requested += newDemand
            }
            /// If buffer isn't ready for flushing, return immediately
            guard demandState.requested > 0 || newDemand == Subscribers.Demand.none else { return .none }
            while !buffer.isEmpty && demandState.processed < demandState.requested {
                demandState.requested += subscriber.receive(buffer.remove(at: 0))
                demandState.processed += 1
            }
            if let completion = completion {
                /// Completion event was already sent
                buffer = []
                demandState = .init()
                self.completion = nil
                subscriber.receive(completion: completion)
                return .none
            }
            let sentDemand = demandState.requested - demandState.sent
            demandState.sent += sentDemand
            return sentDemand
        }
    }
}
