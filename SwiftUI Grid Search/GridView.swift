//
//  ContentView.swift
//  SwiftUI Grid Search
//
//  Created by Matheus Timbó on 20/01/21.
//

import SwiftUI
import Kingfisher

struct RSS: Decodable {
    let feed: Feed
    
}

struct Feed: Decodable {
    let results: [Result]
}

struct Result: Decodable, Hashable {
    let copyright, name, artworkUrl100, releaseDate: String
}

class GridViewModel: ObservableObject {
    @Published var items = 0..<5
    
    @Published var results = [Result]()
    
    init(){
        Timer.scheduledTimer(withTimeInterval: 2, repeats: false) {
            (_) in self.items = 0..<15
        }
        
        guard let url = URL(string: "https://rss.itunes.apple.com/api/v1/us/ios-apps/new-apps-we-love/all/100/explicit.json") else {return}
        
        URLSession.shared.dataTask(with: url) { (data, resp, err) in
            guard let data = data else {return }
            do {
                let rss = try JSONDecoder().decode(RSS.self, from: data)
                self.results = rss.feed.results
            } catch {
                print("Failed to decode: \(error)")
            }
        }.resume()
        
    }
}

struct GridView: View {
    
    @ObservedObject var vm = GridViewModel()
    
    @State var searchText = ""
    @State var isSearching = false
    
    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    HStack {
                        TextField("Type to search...", text:$searchText)
                            .padding(.leading, 24)
                        
                    }
                    .padding()
                    .background(Color(.systemGray5))
                    .cornerRadius(8)
                    .padding(.horizontal)
                    .onTapGesture(perform: {
                        isSearching = true
                    })
                    .overlay(
                        HStack {
                            Image(systemName: "magnifyingglass")
                            Spacer()
                            
                            if isSearching {
                                Button(action: {
                                    searchText = ""
                                }, label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .padding(.vertical)
                                })
                            }
                            
                            
                        }.padding(.horizontal, 32)
                        .foregroundColor(.gray)
                    )
                    .transition(.move(edge: .trailing))
                    .animation(.spring())
                    
                    if isSearching {
                        Button(action: {
                            isSearching = false
                            searchText = ""
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        }, label: {
                            Text("Cancel")
                                .padding(.trailing)
                                .padding(.leading, -12)
                        })
                        .transition(.move(edge: .trailing))
                        .animation(.spring())
                    }
                }
                
                ScrollView{
                    LazyVGrid(columns: [
                        GridItem(.flexible(minimum: 50, maximum: 200), spacing: 16, alignment: .top),
                        GridItem(.flexible(minimum: 50, maximum: 200), spacing: 16, alignment: .top),
                        GridItem(.flexible(minimum: 50, maximum: 200), spacing: 16, alignment: .top)
                    ], alignment: .leading, spacing: 16, content: {
                        ForEach(vm.results.filter({ app in searchText.isEmpty || "\(app.name)".lowercased().contains(searchText.lowercased()) }), id: \.self) { app in
                            AppInfo(app: app)
                        }
                        
                    }).padding(.horizontal, 12)
                }.navigationTitle("Grid Search")
            }
            
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        GridView()
    }
}

struct AppInfo: View {
    let app: Result
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            KFImage(URL(string: app.artworkUrl100))
                .resizable()
                .scaledToFit()
                .cornerRadius(22)
            
            Text(app.name)
                .font(.system(size: 10, weight: .semibold))
                .padding(.top, 4    )
            Text(app.releaseDate)
                .font(.system(size: 9, weight: .regular))
            Text(app.copyright)
                .font(.system(size: 9, weight: .regular))
                .foregroundColor(.gray)
        }
    }
}
