//
//  AnyPublisher.swift
//  
//
//  Created by Dmitry Savinov on 24.03.2022.
//

import Combine
import Foundation

// MARK: - AnyPublisher

extension AnyPublisher {

    // MARK: - Initializers

    /// Effect initializer
    /// - Parameter callback: "Create" callback closure
    private init(_ callback: @escaping (AnyPublisher<Output, Failure>.Subscriber) -> Cancellable) {
        self = Publishers.Create(callback: callback).eraseToAnyPublisher()
    }

    // MARK: - Useful

    /// Static method AnyPublisher initializer
    /// - Parameter factory: "Create" callback closure
    /// - Returns: necessary publisher instance
    public static func create(
        _ factory: @escaping (AnyPublisher<Output, Failure>.Subscriber) -> Cancellable
    ) -> AnyPublisher<Output, Failure> {
        AnyPublisher(factory)
    }

    /// A publisher that awaits subscription before running future to create a publisher for a new subscriber.
    /// - Parameter attemptToFulfill: target fulfil
    /// - Returns: Defered publisher with future wraped with a type eraser.
    public static func deferred(
        _ attemptToFulfill: @escaping (@escaping Future<Output, Failure>.Promise) -> Void
    ) -> AnyPublisher {
        Deferred {
            Future(attemptToFulfill)
        }.eraseToAnyPublisher()
    }

    /// A publisher that eventually produces a single value and then finishes or fails.
    /// - Parameter attemptToFulfill: target fulfil
    /// - Returns: Future publisher wraped with a type eraser.
    public static func future(
        _ attemptToFulfill: @escaping (@escaping Future<Output, Failure>.Promise) -> Void
    ) -> AnyPublisher {
        Future(attemptToFulfill).eraseToAnyPublisher()
    }

    /// A publisher created by applying the merge function to an arbitrary number of upstream publishers.
    /// - Parameter publishers: target publishers for merge
    /// - Returns: MergeMany publisher wraped with a type eraser.
    public static func merge(_ publishers: [AnyPublisher]) -> AnyPublisher {
        Publishers
            .MergeMany(publishers)
            .eraseToAnyPublisher()
    }

    /// Creates a AnyPublisher that executes some work in the real world that doesn't need to feed data back
    /// - Parameter work: target work to execute
    /// - Returns: Deferred Just publisher wraped with a type eraser.
    public static func immediate(_ work: @escaping () -> Void) -> AnyPublisher {
        Deferred { () -> Publishers.CompactMap<Result<Output?, Failure>.Publisher, Output> in
            work()
            return Just<Output?>(nil)
                .setFailureType(to: Failure.self)
                .compactMap { $0 }
        }
        .eraseToAnyPublisher()
    }
}

// MARK: - AnyPublisher+Immediate

extension AnyPublisher where Failure == NSError {

    /// A publisher that immediatly emits an output to each subscriber just once, and then finishes.
    /// Used when Failure is NSError and returns Fail publisher when error is catched.
    /// - Parameter work: target work to execute
    /// - Returns: Just or Fail publisher wraped with a type eraser.
    public static func immediate(_ work: () throws -> Void) -> AnyPublisher {
        do {
            try work()
            return Just<Output?>(nil)
                .setFailureType(to: Failure.self)
                .compactMap { $0 }
                .eraseToAnyPublisher()
        } catch {
            return Fail(error: error as NSError).eraseToAnyPublisher()
        }
    }
}
