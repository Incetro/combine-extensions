//
//  UnsafeMutablePointer.swift
//  
//
//  Created by Dmitry Savinov on 24.03.2022.
//

import Darwin

// MARK: - UnsafeMutablePointer

extension UnsafeMutablePointer where Pointee == os_unfair_lock_s {

    @inlinable
    @discardableResult
    func sync<R>(_ work: () -> R) -> R {
        os_unfair_lock_lock(self)
        defer {
            os_unfair_lock_unlock(self)
        }
        return work()
    }
}
