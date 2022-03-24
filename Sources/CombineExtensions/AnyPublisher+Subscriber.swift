//
//  AnyPublisher+Subscriber.swift
//  
//
//  Created by Dmitry Savinov on 24.03.2022.
//

import Combine

// MARK: - AnyPublisher

public extension AnyPublisher {

    /// AnyPublisher subscriber structure helper
    struct Subscriber {

        // MARK: - Properties

        /// Sender closure
        private let _send: (Output) -> Void

        /// Completion closure
        private let _complete: (Subscribers.Completion<Failure>) -> Void

        // MARK: - Initializers

        /// Default initializer
        /// - Parameters:
        ///   - send: sender closure
        ///   - complete: completion closure
        init(
            send: @escaping (Output) -> Void,
            complete: @escaping (Subscribers.Completion<Failure>) -> Void
        ) {
            self._send = send
            self._complete = complete
        }

        // MARK: - Useful

        /// Sends the given value
        /// - Parameter value: some value
        public func send(_ value: Output) {
            self._send(value)
        }

        /// Send completion event
        /// - Parameter completion: completion event
        public func send(completion: Subscribers.Completion<Failure>) {
            self._complete(completion)
        }
    }

    /// Initializes a publisher from a callback that can send as many values as it wants, and can send
    /// a completion
    ///
    /// This initializer is useful for bridging callback APIs, delegate APIs, and manager APIs to the
    /// `AnyPublisher` type. One can wrap those APIs in an Effect so that its events are sent through the
    /// effect, which allows the reducer to handle them
    ///
    /// For example, one can create an effect to ask for access to `MPMediaLibrary`. It can start by
    /// sending the current status immediately, and then if the current status is `notDetermined` it
    /// can request authorization, and once a status is received it can send that back to the effect:
    ///
    ///     public final class MPMediaLibraryAuthorizationService {
    ///
    ///          public func authorize() -> AnyPublisher<MPMediaLibraryAuthorizationStatus, Never> {
    ///                .run { subscriber in
    ///
    ///                    subscriber.send(MPMediaLibrary.authorizationStatus())
    ///
    ///                    guard MPMediaLibrary.authorizationStatus() == .notDetermined else {
    ///                        subscriber.send(completion: .finished)
    ///                        return AnyCancellable {}
    ///                    }
    ///
    ///                    MPMediaLibrary.requestAuthorization { status in
    ///                        subscriber.send(status)
    ///                        subscriber.send(completion: .finished)
    ///                    }
    ///                 return AnyCancellable {
    ///                     /// Typically clean up resources that were created here, but this effect doesn't
    ///                     /// have any
    ///                 }
    ///             }
    ///         }
    ///      }
    ///
    /// - Parameter work: a closure that accepts a `Subscriber` value and returns a cancellable. When
    ///   the `Effect` is completed, the cancellable will be used to clean up any resources created
    ///   when the effect was started.
    static func run(
        _ work: @escaping (AnyPublisher.Subscriber) -> Cancellable
    ) -> Self {
        AnyPublisher.create(work).eraseToAnyPublisher()
    }
}
