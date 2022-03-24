//
//  Publisher.swift
//  
//
//  Created by Dmitry Savinov on 24.03.2022.
//

import Combine

// MARK: - Publisher

extension Publisher where Output == Never {
    public func asVoid() -> AnyPublisher<Void, Failure> {
        self
            .map { _ in }
            .append(Just(()).setFailureType(to: Failure.self))
            .eraseToAnyPublisher()
    }
}

extension Publisher where Output == Void {
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
