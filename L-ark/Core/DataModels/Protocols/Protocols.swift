//
//  Protocols.swift
//  L-ark
//
//  Created by Jose Rodriguez on 12-09-25.
//

import Foundation


protocol DisplayableError: Error {
    //Para errores de UI
    var userMessage: String { get }
    var isRetryable: Bool { get }
}
