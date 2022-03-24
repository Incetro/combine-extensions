//
//  NSRecursiveLock.swift
//  
//
//  Created by Dmitry Savinov on 24.03.2022.
//

import Foundation

// MARK: - NSRecursiveLock

extension NSRecursiveLock {

    @inlinable
    @discardableResult
    func sync<R>(work: () -> R) -> R {
        lock()
        defer {
            unlock()
        }
        return work()
    }
}
