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

    /// Static method Effect initializer
    /// - Parameter factory: "Create" callback closure
    /// - Returns: necessary publisher instance
    public static func create(
        _ factory: @escaping (AnyPublisher<Output, Failure>.Subscriber) -> Cancellable
    ) -> AnyPublisher<Output, Failure> {
        AnyPublisher(factory)
    }

    public static func deferred(
        _ attemptToFulfill: @escaping (@escaping Future<Output, Failure>.Promise) -> Void
    ) -> AnyPublisher {
        Deferred {
            Future(attemptToFulfill)
        }.eraseToAnyPublisher()
    }

    public static func future(
        _ attemptToFulfill: @escaping (@escaping Future<Output, Failure>.Promise) -> Void
    ) -> AnyPublisher {
        Future(attemptToFulfill).eraseToAnyPublisher()
    }

    public static func immediate(_ work: () -> Void) -> AnyPublisher {
        work()
        return Just<Output?>(nil)
            .setFailureType(to: Failure.self)
            .compactMap { $0 }
            .eraseToAnyPublisher()
    }

    public static func merge(_ publishers: [AnyPublisher]) -> AnyPublisher {
        Publishers
            .MergeMany(publishers)
            .eraseToAnyPublisher()
    }
}

// MARK: - AnyPublisher+Immediate

extension AnyPublisher where Failure == NSError {

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

    public static func immediate(_ work: () -> Void) -> AnyPublisher {
        work()
        return Just<Output?>(nil)
            .setFailureType(to: Failure.self)
            .compactMap { $0 }
            .eraseToAnyPublisher()
    }
}
