//
//MIT License
//
//Copyright © 2025 Cong Le
//
//Permission is hereby granted, free of charge, to any person obtaining a copy
//of this software and associated documentation files (the "Software"), to deal
//in the Software without restriction, including without limitation the rights
//to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//copies of the Software, and to permit persons to whom the Software is
//furnished to do so, subject to the following conditions:
//
//The above copyright notice and this permission notice shall be included in all
//copies or substantial portions of the Software.
//
//THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//SOFTWARE.
//
//  QualiaSpaceView.swift
//  Qualia_Space_in_IIT
//
//  Created by Cong Le on 6/30/25.
//

import SwiftUI
import Charts

// MARK: - Data Models

/// Represents a single element within a conscious complex, such as a neuronal group.
///
/// Each element has a unique identifier and an activity level, which specifies its state
/// at a particular moment. In IIT, the collective state of all elements in a complex
/// defines a specific conscious experience.
///
/// - Note: The activity state of *all* elements, both active and inactive, contributes to defining a point in qualia space.
struct ComplexElement: Identifiable, Hashable {
    let id: Int
    var activityLevel: Double = 0.0
}

/// Defines the structure of causal relationships within a complex.
///
/// This matrix is a simplified representation of the **Effective Information (EI) Matrix** described in IIT.
/// It contains the values of effective information between every subset of elements, defining the geometry
/// of the qualia space (Tononi 2004). For this simulation, we use a simplified dictionary mapping
/// a pair of elements to their causal influence value.
struct EffectiveInformationMatrix {
    let relationships: [Set<Int>: Double]
    
    /// Looks up the effective information between two single elements.
    func ei(from: Int, to: Int) -> Double {
        return relationships[[from, to]] ?? 0.0
    }
}

/// Represents an integrated system capable of consciousness, as defined by IIT.
///
/// A complex is a system of elements with a capacity to integrate information (Φ > 0).
/// The quality of the consciousness it can generate is determined by its internal architecture and the resulting
/// `effectiveInformationMatrix`, which together define its unique "qualia space."
///
/// - SeeAlso: Tononi, Giulio. 2004. “An Information Integration Theory of Consciousness.” *BMC Neuroscience* 5 (1): 42.
struct ConsciousComplex: Identifiable {
    let id = UUID()
    var name: String
    var architectureDescription: String
    var elements: [ComplexElement]
    var effectiveInformationMatrix: EffectiveInformationMatrix
    
    /// Calculates a conceptual 2D coordinate within the complex's qualia space.
    ///
    /// This function provides a simplified projection of a high-dimensional state onto a 2D plane
    /// for visualization. The coordinates for a given activity pattern are fundamentally determined by
    /// the underlying `effectiveInformationMatrix`. This demonstrates why the same activity pattern
    /// produces a different "experience" (i.e., a different point in space) for complexes
    /// with different internal structures.
    ///
    /// - Returns: A tuple `(x: Double, y: Double)` representing the location in the conceptual 2D qualia space.
    func pointInQualiaSpace() -> (x: Double, y: Double) {
        guard elements.count == 4 else { return (x: 0, y: 0) }
        
        // This is a toy projection. The key is that the EI values (the "geometry")
        // are used as weights, ensuring different structures yield different points.
        let ax = elements[0].activityLevel
        let ay = elements[1].activityLevel
        let bx = elements[2].activityLevel
        let by = elements[3].activityLevel

        // **FIX 1: Call `ei` on the `effectiveInformationMatrix` instance.**
        let x = (ax * effectiveInformationMatrix.ei(from: 1, to: 2)) + (ay * effectiveInformationMatrix.ei(from: 2, to: 1)) +
                (bx * effectiveInformationMatrix.ei(from: 3, to: 4)) + (by * effectiveInformationMatrix.ei(from: 4, to: 3))

        let y = (ax * effectiveInformationMatrix.ei(from: 1, to: 3)) + (ay * effectiveInformationMatrix.ei(from: 2, to: 4)) +
                (bx * effectiveInformationMatrix.ei(from: 3, to: 1)) + (by * effectiveInformationMatrix.ei(from: 4, to: 2))
        
        // Normalize to fit the view's coordinate system. A value of 10.0 is used as a heuristic
        // based on the maximum possible EI value in the sample matrices (2.5 * 4).
        // **FIX 2: Return a tuple of Doubles to conform to `Plottable`.**
        return (x: x / 10.0, y: y / 10.0)
    }
}

// MARK: - ViewModel

/// Manages the state and logic for the Qualia Space simulation.
///
/// This view model holds the two example complexes ("Divergent" and "Chain") described in the IIT paper's Figure 2.
/// It provides the data needed by the views and centralizes the logic for updating element activities.
@MainActor
class QualiaViewModel: ObservableObject {
    @Published var complexes: [ConsciousComplex]

    init() {
        // Data is hardcoded based on Figure 2 from Tononi (2004) to illustrate the concept.
        // In a real system, these EI values would be calculated, a computationally intensive process.
        let divergentEI = EffectiveInformationMatrix(relationships: [
            [1, 2]: 2.5, [1, 3]: 2.5, [1, 4]: 2.5
        ])
        
        let chainEI = EffectiveInformationMatrix(relationships: [
            [1, 2]: 2.5, [2, 3]: 2.5, [3, 4]: 2.5
        ])
        
        self.complexes = [
            ConsciousComplex(
                name: "Divergent Complex",
                architectureDescription: "One element sends outputs to all others. This creates a simple, centralized information structure.",
                elements: (1...4).map { ComplexElement(id: $0) },
                effectiveInformationMatrix: divergentEI
            ),
            ConsciousComplex(
                name: "Chain Complex",
                architectureDescription: "Elements are connected in a series. Information flows sequentially through the system.",
                elements: (1...4).map { ComplexElement(id: $0) },
                effectiveInformationMatrix: chainEI
            )
        ]
    }
    
    /// Updates the activity level for a specific element within a complex.
    func updateActivity(for complexID: UUID, elementID: Int, newLevel: Double) {
        guard let complexIndex = complexes.firstIndex(where: { $0.id == complexID }),
              let elementIndex = complexes[complexIndex].elements.firstIndex(where: { $0.id == elementID }) else {
            return
        }
        complexes[complexIndex].elements[elementIndex].activityLevel = newLevel
    }
}

// MARK: - Main SwiftUI View

/// A view demonstrating the concept of "Qualia Space" from Information Integration Theory.
///
/// This view presents two "conscious complexes" with identical numbers of elements and the same
/// overall quantity of integrated information (Φ). However, their internal causal structures
/// (architectures) are different.
///
/// By adjusting the activity levels of their elements, the user can observe how the same pattern of
/// activity results in a different "point" in each complex's unique qualia space. This visually
/// explains IIT's solution to the "second problem of consciousness": the *quality* of an experience
/// is determined by the *shape* of the system's informational relationships, not just the quantity.
struct QualiaSpaceView: View {
    @StateObject private var viewModel = QualiaViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    
                    Text("Problem 2: The Quality of Consciousness")
                        .font(.largeTitle).bold()
                        .padding(.horizontal)

                    Text("IIT proposes that the *quality* of an experience (a 'quale') is determined by the geometry of its 'qualia space.' This space is defined by the unique web of causal relationships within a system, captured by its Effective Information Matrix. Two systems can have the same quantity of consciousness (Φ) but vastly different experiences if their internal informational structures differ.\n\n— Based on Tononi, G. (2004).")
                        .font(.callout)
                        .padding(.horizontal)
                        .foregroundStyle(.secondary)
                    
                    Divider()
                    
                    // Main interactive section comparing the two complexes
                    HStack(alignment: .top, spacing: 20) {
                        ForEach($viewModel.complexes) { $complex in
                            ComplexDetailView(complex: $complex, viewModel: viewModel)
                        }
                    }
                    .padding(.horizontal)
                    
                    Divider()
                    
                    // Shared visualization of the qualia space
                    QualiaSpacePlotView(complexes: viewModel.complexes)
                        .padding(.horizontal)
                    
                }
                .padding(.vertical)
            }
            .navigationTitle("Qualia Space Explorer")
            .navigationBarTitleDisplayMode(.inline)
            .background(Color(.systemGroupedBackground))
        }
    }
}

// MARK: - Subviews

/// Displays the details for a single `ConsciousComplex`.
fileprivate struct ComplexDetailView: View {
    @Binding var complex: ConsciousComplex
    @ObservedObject var viewModel: QualiaViewModel
    
    var body: some View {
        VStack(spacing: 15) {
            Text(complex.name)
                .font(.headline)
            
            Text(complex.architectureDescription)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(height: 60)

            // Visual representation of the complex's architecture
            ComplexArchitectureView(complex: complex)
                .frame(height: 100)

            // Sliders to control element activity
            ForEach(complex.elements) { element in
                ActivitySliderView(
                    elementID: element.id,
                    activityLevel: element.activityLevel,
                    onChanged: { newLevel in
                        viewModel.updateActivity(for: complex.id, elementID: element.id, newLevel: newLevel)
                    }
                )
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
        .shadow(radius: 2, x: 0, y: 1)
    }
}

/// Renders a simple visual representation of the complex architecture.
fileprivate struct ComplexArchitectureView: View {
    let complex: ConsciousComplex
    
    var body: some View {
        Canvas { context, size in
            let nodeRadius: CGFloat = 10
            let positions = [
                CGPoint(x: size.width / 2, y: nodeRadius),
                CGPoint(x: nodeRadius, y: size.height - nodeRadius),
                CGPoint(x: size.width / 2, y: size.height - nodeRadius),
                CGPoint(x: size.width - nodeRadius, y: size.height - nodeRadius)
            ]

            // Draw connections based on architecture
            var path = Path()
            if complex.name.contains("Divergent") {
                path.move(to: positions[0])
                path.addLine(to: positions[1])
                path.move(to: positions[0])
                path.addLine(to: positions[2])
                path.move(to: positions[0])
                path.addLine(to: positions[3])
            } else { // Chain
                path.move(to: positions[0])
                path.addLine(to: positions[2])
                path.move(to: positions[2])
                path.addLine(to: positions[1]) // Visual representation, not literal wiring
                path.move(to: positions[2])
                path.addLine(to: positions[3])
            }
            context.stroke(path, with: .color(.gray), lineWidth: 2)

            // Draw elements
            for (index, pos) in positions.enumerated() {
                let activity = complex.elements[index].activityLevel
                let elementPath = Path(ellipseIn: CGRect(x: pos.x - nodeRadius, y: pos.y - nodeRadius, width: nodeRadius * 2, height: nodeRadius * 2))
                context.fill(elementPath, with: .color(Color.blue.opacity(activity)))
                context.stroke(elementPath, with: .color(.blue), lineWidth: 2)
                context.draw(Text("\(index+1)").font(.caption).bold().foregroundColor(.white), at: pos)
            }
        }
    }
}


/// A slider view to control the activity level of a single element.
fileprivate struct ActivitySliderView: View {
    let elementID: Int
    @State var activityLevel: Double
    let onChanged: (Double) -> Void
    
    var body: some View {
        HStack {
            Image(systemName: "circle.fill")
                .foregroundColor(.blue.opacity(activityLevel))
            Text("E\(elementID)")
                .font(.caption.monospaced())
            Slider(value: $activityLevel, in: 0...1)
                .onChange(of: activityLevel) { _, newValue in
                    onChanged(newValue)
                }
        }
    }
}

/// A view that plots the current state of each complex in a shared "Qualia Space."
fileprivate struct QualiaSpacePlotView: View {
    let complexes: [ConsciousComplex]
    
    var body: some View {
        VStack {
            Text("Conceptual Qualia Space")
                .font(.title3).bold()
            
            Text("The colored dots represent the current conscious state for each complex. Notice how the same activity pattern produces different points in the space, because the underlying geometry (the EI Matrix) is different.")
                .font(.caption)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.bottom, 10)

            Chart {
                let divergentPoint = complexes.first?.pointInQualiaSpace() ?? (x: 0, y: 0)
                let chainPoint = complexes.last?.pointInQualiaSpace() ?? (x: 0, y: 0)

                PointMark(
                    x: .value("Dimension A", divergentPoint.x),
                    y: .value("Dimension B", divergentPoint.y)
                )
                .foregroundStyle(Color.red)
                .symbol(.circle) // **FIX 3: Use .circle enum case**
                .annotation(position: .overlay, alignment: .center) {
                    Text("D")
                        .font(.caption.bold())
                        .foregroundColor(.white)
                }

                PointMark(
                    x: .value("Dimension A", chainPoint.x),
                    y: .value("Dimension B", chainPoint.y)
                )
                .foregroundStyle(Color.green)
                .symbol(.square) // **FIX 3: Use .square enum case**
                .annotation(position: .overlay, alignment: .center) {
                    Text("C")
                        .font(.caption.bold())
                        .foregroundColor(.white)
                }
            }
            .chartXScale(domain: -0.1...1.1)
            .chartYScale(domain: -0.1...1.1)
            .chartXAxisLabel("Qualia Dimension X (Conceptual)")
            .chartYAxisLabel("Qualia Dimension Y (Conceptual)")
            .chartLegend {
                HStack {
                    Image(systemName: "circle.fill").foregroundColor(.red)
                    Text("Divergent Complex State")
                    Spacer()
                    Image(systemName: "square.fill").foregroundColor(.green)
                    Text("Chain Complex State")
                }
                .font(.caption)
                .padding(.top, 5)
            }
            .frame(height: 300)
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(12)
        }
    }
}


// MARK: - Citations and References
/*
 
 CITATIONS:
 
 The conceptual framework for this simulation, including the distinction between
 the quantity (Φ) and quality (qualia) of consciousness, is based on the Information
 Integration Theory (IIT).
 
 The specific examples of the "Divergent" and "Chain" complexes, their architectures,
 and the idea that they can have the same Φ value but different internal causal structures
 (and thus different qualities of experience) are drawn directly from the Firing
 and the theoretical models presented in the foundational paper on the theory.
 
 PRIMARY SOURCE:
 
 Tononi, Giulio. 2004. “An Information Integration Theory of Consciousness.”
 *BMC Neuroscience* 5 (1): 42. https://doi.org/10.1186/1471-2202-5-42.
 (This article is open access and available via PubMed Central®, a U.S. government-funded public resource).
 
 FURTHER READING:
 
 To understand the mathematical formalisms for measuring Φ and the concept of the "main complex",
 the following paper is also essential:
 
 Tononi, Giulio, and Olaf Sporns. 2003. “Measuring Information Integration.”
 *BMC Neuroscience* 4 (1): 31. https://doi.org/10.1186/1471-2202-4-31.
 
 The concepts are also discussed in a more accessible format in:
 
 Edelman, Gerald M., and Giulio Tononi. 2000. *A Universe of Consciousness:
 How Matter Becomes Imagination*. New York, NY: Basic Books.
 
 */


// MARK: - Preview

#Preview {
    QualiaSpaceView()
}
