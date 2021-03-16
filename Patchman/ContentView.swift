//
//  ContentView.swift
//  Patchman
//
//  Created by Praneet S on 16/03/21.
//

import SwiftUI

struct ContentView: View {
    
    @State var url:String = ""
    @State var response: String = ""
    @State var methods: [String] = ["GET", "POST", "PUT", "PATCH", "DELETE"]
    @State var requestBody: [String : Any] = [:]
    @State var params: [String] = []
    @State var headers: [String : String] = [:]
    @State var method: Int = 0
    @State var isParamsEnabled: Bool = false
    @State var isHeaderFieldsEnabled: Bool = false
    @State var headerKey: String = ""
    @State var headerValue: String = ""
    @State var key: String = ""
    @State var value: String = ""
    @State var bodyKey: String = ""
    @State var bodyValue: String = ""
    @State var view: Int = 0
    @State var responseStatus: HTTPURLResponse?
    @State var isResponseHeadersShown: Bool = false
    
    func execute(method: RequestMethod) {
        let req: Request = Request(url: url, method: method, requestBody: requestBody, requestHeaders: headers)
        let res = req.executeRequest()
        responseStatus = res.responseStatus
        response = res.response.prettyPrintedJSONString ?? ""
    }
    
    func getResponseHeaders(response: String) -> String {
        let regex = try! NSRegularExpression(pattern: "Optional\\(<NSHTTPURLResponse: 0x(([0-9]|[a-f]){12})>", options: NSRegularExpression.Options.caseInsensitive)
        let range = NSMakeRange(0, response.count)
        return regex.stringByReplacingMatches(in: response, options: [], range: range, withTemplate: "")
    }
    
    var body: some View {
        onChange(of: url, perform: { _ in
            params = []
        })
        return HStack {
            VStack {
                HStack {
                    Label("Patchman", systemImage: "envelope.open.fill")
                        .font(.title)
                        .padding(.top)
                    Spacer()
                }.padding(.horizontal)
                HStack {
                    TextField("URL", text: $url)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    Picker("Method", selection: $method) {
                        ForEach(0..<methods.count) { index in
                            Text(methods[index])
                        }
                    }
                    .frame(width: 145, height: 45, alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/)
                    Button("Run", action: {
                        switch method {
                        case 0:
                            execute(method: .GET)
                            break
                        case 1:
                            execute(method: .POST)
                            break
                        case 2:
                            execute(method: .PUT)
                            break
                        case 3:
                            execute(method: .PATCH)
                            break
                        case 4:
                            execute(method: .DELETE)
                            break
                        default:
                            break
                        }
                    })
                    Spacer()
                }.padding([.horizontal, .top])
                HStack {
                    Toggle("Query Params", isOn: $isParamsEnabled)
                    Toggle("Header Fields", isOn: $isHeaderFieldsEnabled)
                    Spacer()
                }.padding(.leading)
                if isParamsEnabled {
                    HStack {
                        TextField("Query Parameter", text: $key)
                            .frame(width: 125)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        TextField("Value", text: $value)
                            .frame(width: 125)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        Button("Add", action: {
                            let urlComponents = URLComponents(string: url)
                            guard var urlConstructor = urlComponents else { return }
                            if urlConstructor.queryItems == nil {
                                urlConstructor.queryItems = []
                            }
                            urlConstructor.queryItems!.append(URLQueryItem(name: key, value: value))
                            params.append("\(key) : \(value)")
                            url = urlConstructor.url?.absoluteString ?? url
                        })
                        Spacer()
                    }.padding([.horizontal, .top])
                }
                if isHeaderFieldsEnabled {
                    HStack {
                        TextField("Header field", text: $headerKey)
                            .frame(width: 125)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        TextField("Value", text: $headerValue)
                            .frame(width: 125)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        Button("Add", action: {
                            headers[headerKey] = headerValue
                        })
                        Spacer()
                    }.padding([.horizontal, .top])
                }
                if response.count > 0 {
                    HStack{
                        Label("Response", systemImage: "icloud.and.arrow.down")
                            .font(.title2)
                        Toggle("View response headers", isOn: $isResponseHeadersShown)
                        Spacer()
                        Text("Status: \(responseStatus?.statusCode ?? -1)")
                            .foregroundColor(responseStatus?.statusCode ?? -1 >= 200 && responseStatus?.statusCode ?? -1 < 300 ? .green : .orange)
                    }.padding()
                }
                if method > 0 && method < 4 {
                    HStack {
                        TextField("Request body key", text: $bodyKey)
                            .frame(width: 130)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        TextField("Value", text: $bodyValue)
                            .frame(width: 130)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        Button("Add", action: {
                            requestBody[bodyKey] = bodyValue
                        })
                        Spacer()
                    }.padding([.horizontal, .top])
                }
                ScrollView {
                    HStack {
                        Text(isResponseHeadersShown ? getResponseHeaders(response: "\(responseStatus)") : response)
                            .lineLimit(nil)
                        Spacer()
                    }
                }.padding()
            }.frame(height: 550)
            .frame(minWidth: 600)
            
            VStack{
                
                if params.count > 0 && view == 1 {
                    List(params, id: \.self) { params in
                        Text(params)
                    }
                    .frame(width: 200)
                    .listStyle(SidebarListStyle())
                }
                if headers.count > 0 && view == 0 {
                    List(headers.keys.map({ String($0) }), id: \.self) { key in
                        Text("\(key) : \(headers[key]!)")
                    }
                    .frame(width: 200)
                    .listStyle(SidebarListStyle())
                }
                if requestBody.count > 0 && view == 2 {
                    List(requestBody.keys.map({ String($0) }), id: \.self) { key in
                        Text("\(key) : \(requestBody[key]! as? String ?? "Not representable")")
                    }
                    .frame(width: 200)
                    .listStyle(SidebarListStyle())
                }
                
            }
        }.toolbar(content: {
            HStack {
                if headers.count > 0 || params.count > 0 || requestBody.count > 0 {
                    Picker("", selection: $view){
                        if headers.count > 0 {
                            Text("Header fields").tag(0)
                        }
                        if params.count > 0 {
                            Text("Query Params").tag(1)
                        }
                        if requestBody.count > 0 && method > 0 && method < 4 {
                            Text("Request body").tag(2)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .frame(width: 275)
                }
                
                if headers.count > 0 {
                    Button("Delete headers"){
                        headers = [:]
                    }
                }
                if requestBody.count > 0 {
                    Button("Delete body"){
                        requestBody = [:]
                    }
                }
            }
        })
    }
}

extension Data {
    var prettyPrintedJSONString: String? {
        guard let object = try? JSONSerialization.jsonObject(with: self, options: []),
              let data = try? JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted]),
              let prettyPrintedString = String(data: data, encoding: .utf8) else { return nil }
        
        return prettyPrintedString
    }
}
