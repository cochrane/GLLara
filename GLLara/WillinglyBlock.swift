//
//  WillinglyBlock.swift
//  GLLara
//
//  Created by Torsten Kammer on 18.02.23.
//  Copyright © 2023 Torsten Kammer. All rights reserved.
//

import Foundation

class ResultHolder<Result> {
    var result: Result? = nil
    var error: Error? = nil
}

func throwingRunAndBlock(_ action: @escaping @Sendable () async throws -> Void ) throws {
    let semaphore = DispatchSemaphore(value: 0)
    
    let holder = ResultHolder<Void>()
    
    Task {
        do {
            try await action()
        } catch {
            holder.error = error
        }
        semaphore.signal()
    }
    
    semaphore.wait()
    if let error = holder.error {
        throw error
    }
}

func runAndBlockReturn<T>(_ action: @escaping @Sendable () async -> T) -> T {
    let semaphore = DispatchSemaphore(value: 0)
    
    let holder = ResultHolder<T>()
    
    Task {
        holder.result = await action()
        semaphore.signal()
    }
    
    semaphore.wait()
    return holder.result!
}

func throwingRunAndBlockReturn<T>(_ action: @escaping @Sendable () async throws -> T ) throws -> T {
    let semaphore = DispatchSemaphore(value: 0)
    
    let holder = ResultHolder<T>()
    
    Task {
        do {
            holder.result = try await action()
        } catch {
            holder.error = error
        }
        semaphore.signal()
    }
    
    semaphore.wait()
    if let error = holder.error {
        throw error
    }
    return holder.result!
}
