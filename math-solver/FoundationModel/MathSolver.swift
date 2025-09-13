//
//  MathSolver.swift
//  math-solver
//
//  Created by SownFrenky on 9/13/25.
//

import Foundation
import FoundationModels

actor MathSolver {
    private var model: SystemLanguageModel
    private var modelSession: LanguageModelSession = L
    
    
    init(model: SystemLanguageModel, modelSession: LanguageModelSession) {
        self.model = model
        self.modelSession = modelSession
    }
}
