//
//  MainBGContainer.swift
//  L-ark
//
//  Created by Jose Rodriguez on 26-08-25.
//

import SwiftUI


struct MainBGContainer<Content: View>: View {
    
    let content: Content
    
    init(@ViewBuilder content: () -> Content){
        self.content = content()
    }
    
    var body: some View {
        
        ZStack{
            
            LinearGradient(colors:[   Color.primaryBackground,Color.secondaryBackground, Color.terciaryBackground], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea(edges: .all)
            
            content
            
            
            
        }
        
    }
}
#Preview {
    MainBGContainer {
        Text("Hola, soy el contenido!")
            .foregroundColor(Color.black)
        Image(systemName: "star.fill")
            .foregroundColor(Color.red)
            .font(.largeTitle)
            .padding(.top, 410)
    }
}
