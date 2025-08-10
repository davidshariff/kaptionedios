import SwiftUI

struct BottomSheetView<Content: View>: View {
    @Binding var isPresented: Bool
    @State private var showSheet: Bool = false
    @State private var slideGesture: CGSize
    var bgOpacity: CGFloat
    var sheetOpacity: CGFloat
    var allowDismiss: Bool
    let content: Content
    init(isPresented: Binding<Bool>, bgOpacity: CGFloat = 0.01, sheetOpacity: CGFloat = 1.0, allowDismiss: Bool = true, @ViewBuilder content: () -> Content){
        self._isPresented = isPresented
        self.bgOpacity = bgOpacity
        self.sheetOpacity = sheetOpacity
        self.allowDismiss = allowDismiss
        self._slideGesture = State(initialValue: CGSize.zero)
        self.content = content()
        
    }
    var body: some View {
        ZStack(alignment: .bottom){
            Color.black.opacity(bgOpacity)
                .onTapGesture {
                    if allowDismiss {
                        closeSheet()
                    }
                }
                .onAppear{
                    withAnimation(.spring().delay(0.1)){
                        showSheet = true
                    }
                }
            if showSheet{
                sheetLayer
                    .transition(.move(edge: .bottom))
                    .onDisappear{
                        withAnimation(.easeIn(duration: 0.1)){
                            isPresented = false
                        }
                    }
            }
        }
    }
}


extension BottomSheetView{
    private var sheetLayer: some View{
        VStack(spacing: 0){
            HStack(alignment: .top, spacing: -20){
                Spacer()
                Capsule()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 80, height: 6)
                Spacer()
                if allowDismiss {
                    Button {
                        closeSheet()
                    } label: {
                        Image(systemName: "xmark")
                            .imageScale(.medium)
                            .foregroundColor(.white)
                    }
                } else {
                    // Invisible spacer to maintain layout
                    Image(systemName: "xmark")
                        .imageScale(.medium)
                        .foregroundColor(.clear)
                }
            }
            .padding(.top, 10)
            .padding(.horizontal)
            content
                .padding(.horizontal)
                .padding(.top, 10)
                .padding(.bottom, 40)
        }
        .frame(maxWidth: .infinity)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: -5)
        .opacity(sheetOpacity)
        .gesture(
            allowDismiss ? 
            DragGesture().onChanged{ value in
                self.slideGesture = value.translation
            }
            .onEnded{ value in
                if self.slideGesture.height > -10 {
                    closeSheet()
                }
                self.slideGesture = .zero
            } : nil
        )
    }
    
    private func closeSheet(){
        withAnimation(.easeIn(duration: 0.2)){
            showSheet = false
        }
    }
}





