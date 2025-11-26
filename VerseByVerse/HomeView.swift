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
                .font(.system(size: 24))
            Text("HomeView - Funnel Sans")
                .font(.custom("Funnel Sans", size: 24))
            Text("HomeView - Montserrat")
                .font(.custom("Montserrat", size: 24))
            Text("HomeView - Roboto")
                .font(.custom("Roboto", size: 24))
            Text("HomeView - Rubik")
                .font(.custom("Rubik", size: 24))
        }
        .padding()
    }
}

#Preview {
    HomeView()
}
