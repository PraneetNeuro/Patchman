//
//  ContentView.swift
//  Patchman
//
//  Created by Praneet S on 16/03/21.
//

import SwiftUI

struct LogoView: View {
    var body: some View {
        HStack {
            Label("Patchman", systemImage: "envelope.open.fill")
                .font(.title)
                .padding(.top)
            Spacer()
        }.padding(.horizontal)
    }
}

struct ActionBarView: View {
    
    @Binding var url: String
    @Binding var methods: [String]
    @Binding var method: Int
    @Binding var isProcessing: Bool
    @Binding var isBulkRequest: Bool
    @Binding var response: String
    @Binding var bulkResponsesStatusCodes: [Int]
    @Binding var bulkRequestBody: [[String : Any]]
    @Binding var headers: [String : String]
    @Binding var requestBody: [String : Any]
    @Binding var responseStatus: HTTPURLResponse?
    
    func execute(method: RequestMethod) {
        isProcessing = true
        if isBulkRequest {
            DispatchQueue.global().async {
                response = ""
                bulkResponsesStatusCodes = []
                for reqBody in bulkRequestBody {
                    let req: Request = Request(url: url, method: method, requestBody: reqBody, requestHeaders: headers)
                    let res = req.executeRequest()
                    responseStatus = res.responseStatus
                    response += "\t\t---START OF RESPONSE---\n" + (res.response.prettyPrintedJSONString ?? "") + "\n\t\t---END OF RESPONSE---\n\n"
                    bulkResponsesStatusCodes.append(res.responseStatus?.statusCode ?? -1)
                }
            }
        } else {
            let req: Request = Request(url: url, method: method, requestBody: requestBody, requestHeaders: headers)
            let res = req.executeRequest()
            responseStatus = res.responseStatus
            response = res.response.prettyPrintedJSONString ?? ""
            isProcessing = false
        }
    }
    
    var body: some View {
        HStack {
            TextField("URL", text: $url)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            Picker("Method", selection: $method) {
                ForEach(0..<methods.count) { index in
                    Text(methods[index])
                }
            }
            .frame(width: 145, height: 45)
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
            }).disabled(isProcessing)
            Spacer()
        }.padding([.horizontal, .top])
    }
}

struct BulkStatusListView: View {
    
    @Binding var bulkResponses: [Int]
    @Binding var isProcessing: Bool
    @Binding var bulkRequestBody: [[String : Any]]
    
    var green: Color = .init(red: (146 / 255), green: (222 / 255), blue: (167 / 255))
    var red: Color = .init(red: (222 / 255), green: (146 / 255), blue: (146 / 255))
    
    private func isStatusOkay(statusCode: Int) -> Bool {
        return statusCode >= 200 && statusCode < 300
    }
    
    var body: some View {
        HStack {
            ScrollView {
                VStack(alignment: .leading) {
                    ForEach(bulkResponses, id: \.self) { response in
                        Text("Status: \(response)")
                            .bold()
                            .background(
                                Rectangle()
                                    .frame(width: 90, height: 30)
                                    .foregroundColor(isStatusOkay(statusCode: response) ? green : red )
                                    .border(isStatusOkay(statusCode: response) ? Color.green : Color.red, width: 3)
                                    .cornerRadius(6))
                            .padding()
                    }
                }.padding()
            }.onChange(of: bulkResponses, perform: { _ in
                isProcessing = bulkResponses.count != bulkRequestBody.count
                print(isProcessing)
            })
            Spacer()
        }.padding()
    }
}

struct FieldsToggleView: View {
    @Binding var isParamsEnabled: Bool
    @Binding var isHeaderFieldsEnabled: Bool
    @Binding var isBulkRequest: Bool
    @Binding var bulkRequestBody: [[String : Any]]
    
    func pickFile() -> String? {
        let dialog = NSOpenPanel();
        
        dialog.title  = "Choose a CSV file";
        dialog.showsResizeIndicator = true;
        dialog.showsHiddenFiles = false;
        dialog.allowsMultipleSelection = false;
        dialog.canChooseDirectories = false;
        dialog.allowedFileTypes = ["csv"];
        
        if (dialog.runModal() ==  NSApplication.ModalResponse.OK) {
            let result = dialog.url
            if (result != nil) {
                let path: String = result!.path
                return path
            }
        } else {
            return nil
        }
        return nil
    }
    
    var body: some View {
        HStack {
            Toggle("Query Params", isOn: $isParamsEnabled)
            Toggle("Header Fields", isOn: $isHeaderFieldsEnabled)
            Toggle("Bulk requests", isOn: $isBulkRequest)
            if isBulkRequest {
                Button(action: {
                    guard let bulkRequestBodyFilePath: String = pickFile() else { return }
                    do {
                        let bulkRequestBodyContents = try String(contentsOf: URL(fileURLWithPath: bulkRequestBodyFilePath))
                        var bulkRequestBodyCSVs = bulkRequestBodyContents.split(separator: "\n").map({ String($0) })
                        let keys = bulkRequestBodyCSVs.first!.split(separator: ",")
                        bulkRequestBodyCSVs = bulkRequestBodyCSVs.dropFirst().map({ String($0) })
                        for field in bulkRequestBodyCSVs {
                            
                            let fieldDecoded = field.split(separator: ",")
                            if fieldDecoded.count == keys.count {
                                var bodyField: [String : Any] = [:]
                                for index in 0..<keys.count {
                                    bodyField[String(keys[index])] = String(fieldDecoded[index]).trimmingCharacters(in: .whitespaces)
                                }
                                print(bodyField)
                                bulkRequestBody.append(bodyField)
                            }
                        }
                    } catch {
                        print(error)
                    }
                }, label: {
                    Image(systemName: "folder.badge.plus")
                })
            }
            Spacer()
        }.padding(.leading)
    }
}

struct HeadersEnabledView: View {
    @Binding var isHeaderFieldsEnabled: Bool
    @Binding var headerKey: String
    @Binding var headerValue: String
    @Binding var headers: [String : String]
    var body: some View {
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
    }
}

struct ParamsEnabledView: View {
    @Binding var isParamsEnabled: Bool
    @Binding var key: String
    @Binding var value: String
    @Binding var url: String
    var body: some View {
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
                    url = urlConstructor.url?.absoluteString ?? url
                })
                Spacer()
            }.padding([.horizontal, .top])
        }
    }
}

struct ResponseHeaderAndOptionsView: View {
    @Binding var response: String
    @Binding var responseStatus: HTTPURLResponse?
    @Binding var isResponseHeadersShown: Bool
    @Binding var isBulkResponseStatusesShown: Bool
    @Binding var isBulkRequest: Bool
    var body: some View {
        if response.count > 0 {
            HStack{
                Label("Response", systemImage: "icloud.and.arrow.down")
                    .font(.title2)
                Toggle("View response headers", isOn: $isResponseHeadersShown)
                if isBulkRequest {
                    Toggle("View bulk response statuses", isOn: $isBulkResponseStatusesShown)
                }
                Spacer()
                if !isBulkResponseStatusesShown {
                    Text("Status: \(responseStatus?.statusCode ?? -1)")
                        .foregroundColor(responseStatus?.statusCode ?? -1 >= 200 && responseStatus?.statusCode ?? -1 < 300 ? .green : .orange)
                }
            }.padding()
        }
    }
}

struct BodyFillerView: View {
    @Binding var method: Int
    @Binding var bodyKey: String
    @Binding var bodyValue: String
    @Binding var requestBody: [String : Any]
    var body: some View {
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
    }
}

struct ProfileView: View {
    var profile: Profile
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(profile.profileName)
                    .bold()
                    .lineLimit(2)
                    .padding(.leading, 4)
                Spacer()
            }
        }
        .frame(width: 165, height: 35)
        .background(Rectangle().frame(width: 165, height: 35).foregroundColor(.gray).opacity(0.45).cornerRadius(6))
    }
}

struct PresetView: View {
    var preset: Preset
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(preset.presetType == 0 ? "Header Field" : "Body Field")
                    .font(.subheadline)
                    .bold()
                    .padding(.leading, 4)
                Spacer()
            }
            HStack {
                Text(preset.presetName)
                    .bold()
                    .lineLimit(2)
                    .padding(.leading, 4)
                Spacer()
            }
        }
        .frame(width: 165, height: 55)
        .background(Rectangle().frame(width: 165, height: 55).foregroundColor(.gray).opacity(0.45).cornerRadius(6))
    }
}

struct ContentView: View {
    
    @State var url:String = ""
    @State var response: String = ""
    @State var methods: [String] = ["GET", "POST", "PUT", "PATCH", "DELETE"]
    @State var requestBody: [String : Any] = [:]
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
    @State var isBulkResponseStatusesShown: Bool = false
    @State var bulkResponsesStatusCodes: [Int] = []
    @State var isProcessing: Bool = false
    @State var presetType: Int = 0
    @State var presetKey: String = ""
    @State var presetValue: String = ""
    @State var presetName: String = ""
    @State var defaultPresets: [Preset] = retreiveDefaultPresets()
    @State var defaultProfiles: [Profile] = retreiveDefaultProfiles()
    @State var isPresetAddShown: Bool = false
    @State var bulkRequestBody: [[String : Any]] = []
    @State var isBulkRequest: Bool = false
    @State var profileName: String = ""
    
    func getResponseHeaders(response: String) -> String {
        let regex = try! NSRegularExpression(pattern: "Optional\\(<NSHTTPURLResponse: 0x(([0-9]|[a-f]){12})>", options: NSRegularExpression.Options.caseInsensitive)
        let range = NSMakeRange(0, response.count)
        return regex.stringByReplacingMatches(in: response, options: [], range: range, withTemplate: "")
    }
    
    func saveProfile() {
        let p = Profile(profileName: profileName, method: method, url: url, headers: headers, requestBody: requestBody as? [String : JSONValue] ?? [:], isHeadersEnabled: isHeaderFieldsEnabled, isBulkRequest: isBulkRequest, bulkRequestBody: bulkRequestBody as? [[String : JSONValue]] ?? [[:]])
        p.save()
        defaultProfiles.append(p)
        print(retreiveDefaultProfiles())
    }
    
    var body: some View {
        HStack {
            VStack {
                List {
                    Text("Presets")
                        .bold()
                        .font(.title2)
                    Toggle("Add preset", isOn: $isPresetAddShown)
                    if isPresetAddShown {
                        Picker("", selection: $presetType){
                            Text("Header Field").tag(0)
                            Text("Body").tag(1)
                        }.pickerStyle(SegmentedPickerStyle())
                        Text("Preset Name")
                        TextEditor(text: $presetName)
                            .cornerRadius(6)
                        Text("Key")
                        TextEditor(text: $presetKey)
                            .cornerRadius(6)
                        Text("Value")
                        TextEditor(text: $presetValue)
                            .cornerRadius(6)
                        Button("Add preset"){
                            if presetKey.count > 0 && presetValue.count > 0 && presetName.count > 0 {
                                let preset = Preset(presetType: presetType, key: presetKey, value: presetValue, presetName: presetName)
                                preset.save()
                                defaultPresets.append(preset)
                            }
                        }.padding(.bottom)
                    }
                    ForEach(defaultPresets, id: \.key){ preset in
                        PresetView(preset: preset)
                            .onTapGesture {
                                switch preset.presetType {
                                case 0:
                                    headers[preset.key] = preset.value
                                    break
                                case 1:
                                    requestBody[preset.key] = preset.value
                                    break
                                default:
                                    break
                                }
                            }
                    }
                    Text(defaultProfiles.count > 0 ? "Profiles" : "")
                        .bold()
                        .font(.title2)
                        .padding(.top)
                    ForEach(defaultProfiles, id: \.profileName){ profile in
                        ProfileView(profile: profile)
                            .onTapGesture {
                                url = profile.url
                                method = profile.method
                                headers = profile.headers
                                requestBody = profile.requestBody
                                isHeaderFieldsEnabled = profile.isHeadersEnabled
                                isBulkRequest = profile.isBulkRequest
                                bulkRequestBody = profile.bulkRequestBody
                            }
                    }
                }.frame(minWidth: 200, maxWidth: 200)
            }.listStyle(SidebarListStyle())
            
            VStack {
                HStack{
                    LogoView()
                    Spacer()
                    TextField("Profile name", text: $profileName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 145)
                    Button(action: {
                        if profileName.count > 0 {
                            saveProfile()
                        }
                    }, label: {
                        Image(systemName: "square.and.arrow.down")
                    }).padding()
                }
                
                ActionBarView(url: $url, methods: $methods, method: $method, isProcessing: $isProcessing, isBulkRequest: $isBulkRequest, response: $response, bulkResponsesStatusCodes: $bulkResponsesStatusCodes, bulkRequestBody: $bulkRequestBody, headers: $headers, requestBody: $requestBody, responseStatus: $responseStatus)
                
                FieldsToggleView(isParamsEnabled: $isParamsEnabled, isHeaderFieldsEnabled: $isHeaderFieldsEnabled, isBulkRequest: $isBulkRequest, bulkRequestBody: $bulkRequestBody)
                
                ParamsEnabledView(isParamsEnabled: $isParamsEnabled, key: $key, value: $value, url: $url)
                
                HeadersEnabledView(isHeaderFieldsEnabled: $isHeaderFieldsEnabled, headerKey: $headerKey, headerValue: $headerValue, headers: $headers)
                
                if !isBulkRequest {
                    BodyFillerView(method: $method, bodyKey: $bodyKey, bodyValue: $bodyValue, requestBody: $requestBody)
                }
                
                ResponseHeaderAndOptionsView(response: $response, responseStatus: $responseStatus, isResponseHeadersShown: $isResponseHeadersShown, isBulkResponseStatusesShown: $isBulkResponseStatusesShown, isBulkRequest: $isBulkRequest)
                
                if isBulkResponseStatusesShown {
                    BulkStatusListView(bulkResponses: $bulkResponsesStatusCodes, isProcessing: $isProcessing, bulkRequestBody: $bulkRequestBody)
                    Text("\(bulkResponsesStatusCodes.filter({ $0 >= 200 && $0 < 300 }).count) / \(bulkRequestBody.count) requests successful")
                        .bold()
                        .padding()
                } else {
                    ScrollView {
                        HStack {
                            Text(isResponseHeadersShown ? getResponseHeaders(response: "\(responseStatus)") : response)
                                .lineLimit(nil)
                                .onChange(of: bulkResponsesStatusCodes, perform: { _ in
                                    if bulkResponsesStatusCodes.count == bulkRequestBody.count {
                                        isProcessing = false
                                    }
                                })
                            Spacer()
                        }
                    }.padding()
                }
            }.frame(height: 550)
            .frame(minWidth: 600)
            VStack{
                
                List {
                    Text(headers.count > 0 ? "Header fields" : "")
                        .font(.title2)
                        .bold()
                    ForEach(headers.keys.map({ String($0) }), id: \.self) { key in
                        HStack {
                            Button(action: {
                                headers.removeValue(forKey: key)
                            }, label: {
                                Image(systemName: "trash")
                            })
                            Text("\(key) : \(headers[key]!)")
                            Spacer()
                        }
                    }
                    .frame(width: 200)
                    
                    
                    Text(requestBody.count > 0 ? "Request Body fields" : "")
                        .font(.title2)
                        .bold()
                    ForEach(requestBody.keys.map({ String($0) }), id: \.self) { key in
                        HStack {
                            Button(action: {
                                requestBody.removeValue(forKey: key)
                            }, label: {
                                Image(systemName: "trash")
                            })
                            Text("\(key) : \(requestBody[key]! as? String ?? "Not representable")")
                            Spacer()
                        }
                    }
                    .frame(width: 200)
                }
                .listStyle(SidebarListStyle())
            }.frame(minWidth: 200, maxWidth: 200)
        }
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
