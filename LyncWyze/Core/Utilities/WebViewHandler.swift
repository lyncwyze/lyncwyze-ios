//
//  WebViewHandler.swift
//  LyncWyze
//
//  Created by Abhijeet Nag on 04/04/25.
//

import SwiftUI

struct WebViewHandler: View {
    @State private var isLoading = true
    var navigationTitle: String
    var urlString: String

    var body: some View {
        ZStack {
            WebView(url: URL(string: urlString)!, isLoading: $isLoading)

            if isLoading {
                ProgressView("Loading...")
                    .progressViewStyle(CircularProgressViewStyle())
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.white.opacity(0.6))
            }
        }
        .navigationTitle(navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
    }
}
