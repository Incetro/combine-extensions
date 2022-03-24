//
//  Publisher.swift
//  
//
//  Created by Dmitry Savinov on 24.03.2022.
//

import Combine

// MARK: - Publisher

extension Publisher where Output == Never {

    /// Converts publisher to empty Just publisher and erases to AnyPublisher
    /// - Returns: Void AnyPublisher
    public func asVoid() -> AnyPublisher<Void, Failure> {
        self
            .map { _ in }
            .append(Just(()).setFailureType(to: Failure.self))
            .eraseToAnyPublisher()
    }
}

extension Publisher where Output == Void {

    /// Ignores all upstream elements, but passes along the upstream publisher’s completion state (finished or failed).
    /// - Parameter completeImmediately: if true - immediately finishes, otherwise just ignores output.
    /// - Returns: Type erased AnyPublisher with ignored output.
    public func asNever(completeImmediately: Bool) -> AnyPublisher<Never, Failure> {
        if completeImmediately {
            return Just<Void>(())
                .setFailureType(to: Failure.self)
                .merge(with: self)
                .first()
                .ignoreOutput()
                .eraseToAnyPublisher()
        } else {
            return self
                .ignoreOutput()
                .eraseToAnyPublisher()
        }
    }
}
