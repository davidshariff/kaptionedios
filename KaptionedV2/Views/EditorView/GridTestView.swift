import SwiftUI

struct GridTestView: View {
    
    // Grid configuration
    var gridSpacing: CGFloat = 25
    var gridColor: Color = .white.opacity(0.3)
    var textColor: Color = .white.opacity(0.8)
    var originalVideoSize: CGSize = CGSize(width: 1920, height: 1080) // Default 16:9
    
    // New properties for explicit grid control
    var gridColumns: Int? = nil // If nil, will calculate based on spacing
    var gridRows: Int? = nil // If nil, will calculate based on spacing
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Grid lines
                gridLines(in: geometry.size)
                
                // Grid boxes with numbers
                gridBoxes(in: geometry.size)
            }
        }
    }
    
    private func calculateScaleFactor(for size: CGSize) -> CGFloat {
        // Calculate scale factor based on video aspect ratio
        let scaleX = size.width / originalVideoSize.width
        let scaleY = size.height / originalVideoSize.height
        return min(scaleX, scaleY) // Use the smaller scale to maintain aspect ratio
    }
    
    private func scaledGridSpacing(for size: CGSize) -> CGFloat {
        return gridSpacing * calculateScaleFactor(for: size)
    }
    
    private func getGridDimensions(for size: CGSize) -> (columns: Int, rows: Int, spacing: CGFloat) {
        let scaleFactor = calculateScaleFactor(for: size)
        let scaledSpacing = gridSpacing * scaleFactor
        
        // Use explicit dimensions if provided, otherwise calculate based on spacing
        let columns = gridColumns ?? max(1, Int(size.width / scaledSpacing))
        let rows = gridRows ?? max(1, Int(size.height / scaledSpacing))
        
        // Recalculate spacing to fit the view exactly with the specified dimensions
        let calculatedSpacing = min(
            size.width / CGFloat(columns),
            size.height / CGFloat(rows)
        )
        
        return (columns: columns, rows: rows, spacing: calculatedSpacing)
    }
    
    private func gridLines(in size: CGSize) -> some View {
        let dimensions = getGridDimensions(for: size)
        let spacing = dimensions.spacing
        
        return ZStack {
            // Vertical lines
            ForEach(0...dimensions.columns, id: \.self) { index in
                let x = CGFloat(index) * spacing - size.width / 2
                Rectangle()
                    .fill(gridColor)
                    .frame(width: 1, height: size.height)
                    .offset(x: x)
            }
            
            // Horizontal lines
            ForEach(0...dimensions.rows, id: \.self) { index in
                let y = CGFloat(index) * spacing - size.height / 2
                Rectangle()
                    .fill(gridColor)
                    .frame(width: size.width, height: 1)
                    .offset(y: y)
            }
        }
    }
    
    private func gridBoxes(in size: CGSize) -> some View {
        let dimensions = getGridDimensions(for: size)
        let spacing = dimensions.spacing
        let scaleFactor = calculateScaleFactor(for: size)
        
        return ZStack {
            ForEach(0..<dimensions.columns, id: \.self) { xIndex in
                ForEach(0..<dimensions.rows, id: \.self) { yIndex in
                    let x = CGFloat(xIndex) * spacing - size.width / 2 + spacing / 2
                    let y = CGFloat(yIndex) * spacing - size.height / 2 + spacing / 2
                    let boxNumber = yIndex * dimensions.columns + xIndex + 1
                    
                    Text("\(boxNumber)")
                        .font(.system(size: 10 * scaleFactor, weight: .medium))
                        .foregroundColor(textColor)
                        .frame(width: spacing, height: spacing)
                        .offset(x: x, y: y)
                }
            }
        }
    }
}

struct GridTestView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            // Example with explicit grid dimensions
            ZStack {
                Color.black
                GridTestView(gridColumns: 4, gridRows: 3)
            }
            .frame(width: 300, height: 200)
            
            // Example with spacing-based calculation (original behavior)
            ZStack {
                Color.black
                GridTestView(gridSpacing: 30)
            }
            .frame(width: 300, height: 200)
        }
    }
} 