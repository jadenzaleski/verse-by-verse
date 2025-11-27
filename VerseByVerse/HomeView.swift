//
//  HomeView.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 11/25/25.
//

import SwiftUI

struct HomeView: View {
    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
            .font(.body)

        VStack(alignment: .leading) {
            Text("HomeView - System")
                .font(.body)
            Text("HomeView - Montserrat")

        }
        .padding()
    }
}

#Preview {
    HomeView()
        .environment(\.font, .app())
}
