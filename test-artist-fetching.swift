#!/usr/bin/env swift

import Foundation

// Test script to verify artist fetching from Supabase
print("🎵 Testing Artist Fetching from Supabase")
print(String(repeating: "=", count: 50))

// Test configuration - requires environment variables
guard let supabaseURL = ProcessInfo.processInfo.environment["SUPABASE_URL"] else {
    print("❌ Error: SUPABASE_URL environment variable not set")
    print("Please set: export SUPABASE_URL=\"your-supabase-url\"")
    exit(1)
}
guard let supabaseKey = ProcessInfo.processInfo.environment["SUPABASE_ANON_KEY"] else {
    print("❌ Error: SUPABASE_ANON_KEY environment variable not set")
    print("Please set: export SUPABASE_ANON_KEY=\"your-anon-key\"")
    exit(1)
}

print("🔧 Configuration:")
print("URL: \(String(supabaseURL.prefix(30)))...")
print("Key: \(String(supabaseKey.prefix(20)))...")

// Test 1: Fetch all artists
print("\n📋 Test 1: Fetching all artists...")
let artistsURL = URL(string: "\(supabaseURL)/rest/v1/artists?select=*&limit=10")!
var request = URLRequest(url: artistsURL)
request.setValue(supabaseKey, forHTTPHeaderField: "apikey")
request.setValue("Bearer \(supabaseKey)", forHTTPHeaderField: "Authorization")
request.setValue("application/json", forHTTPHeaderField: "Accept")

let semaphore = DispatchSemaphore(value: 0)
var testResults: [String: Any] = [:]

let task = URLSession.shared.dataTask(with: request) { data, response, error in
    if let error = error {
        print("❌ Error: \(error.localizedDescription)")
        testResults["allArtists"] = "Failed: \(error.localizedDescription)"
    } else if let httpResponse = response as? HTTPURLResponse {
        print("📡 Response status: \(httpResponse.statusCode)")
        
        if httpResponse.statusCode == 200, let data = data {
            do {
                if let jsonArray = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                    print("✅ Successfully fetched \(jsonArray.count) artists")
                    testResults["allArtists"] = "Success: \(jsonArray.count) artists"
                    
                    // Display first 5 artists
                    print("\n🎭 Sample artists:")
                    for (index, artist) in jsonArray.prefix(5).enumerated() {
                        let id = artist["id"] as? String ?? "No ID"
                        let name = artist["name"] as? String ?? "No Name" 
                        let displayName = artist["display_name"] as? String
                        let type = artist["type"] as? String ?? "Unknown"
                        let agency = artist["agency"] as? String ?? "Unknown"
                        
                        print("\(index + 1). \(name)")
                        print("   ID: \(String(id.prefix(8)))...")
                        if let displayName = displayName, displayName != name {
                            print("   Display: \(displayName)")
                        }
                        print("   Type: \(type), Agency: \(agency)")
                        
                        // Store first artist ID for Test 2
                        if index == 0 {
                            testResults["firstArtistId"] = id
                            testResults["firstArtistName"] = name
                        }
                    }
                } else {
                    print("❌ Invalid JSON format")
                    testResults["allArtists"] = "Failed: Invalid JSON"
                }
            } catch {
                print("❌ JSON parsing error: \(error)")
                testResults["allArtists"] = "Failed: JSON parsing error"
            }
        } else {
            print("❌ HTTP error: \(httpResponse.statusCode)")
            if let data = data, let errorString = String(data: data, encoding: .utf8) {
                print("Error details: \(errorString)")
            }
            testResults["allArtists"] = "Failed: HTTP \(httpResponse.statusCode)"
        }
    }
    semaphore.signal()
}
task.resume()
semaphore.wait()

// Test 2: Fetch artist by ID (if we got one from Test 1)
if let firstArtistId = testResults["firstArtistId"] as? String,
   let firstArtistName = testResults["firstArtistName"] as? String {
    
    print("\n🔍 Test 2: Fetching artist by ID...")
    print("Looking for: \(firstArtistName) (ID: \(String(firstArtistId.prefix(8)))...)")
    
    let artistByIdURL = URL(string: "\(supabaseURL)/rest/v1/artists?id=eq.\(firstArtistId)&select=*")!
    var artistRequest = URLRequest(url: artistByIdURL)
    artistRequest.setValue(supabaseKey, forHTTPHeaderField: "apikey")
    artistRequest.setValue("Bearer \(supabaseKey)", forHTTPHeaderField: "Authorization")
    artistRequest.setValue("application/json", forHTTPHeaderField: "Accept")
    
    let artistTask = URLSession.shared.dataTask(with: artistRequest) { data, response, error in
        if let error = error {
            print("❌ Error fetching artist by ID: \(error.localizedDescription)")
        } else if let httpResponse = response as? HTTPURLResponse {
            print("📡 Response status: \(httpResponse.statusCode)")
            
            if httpResponse.statusCode == 200, let data = data {
                do {
                    if let jsonArray = try JSONSerialization.jsonObject(with: data) as? [[String: Any]],
                       let artist = jsonArray.first {
                        let name = artist["name"] as? String ?? "No Name"
                        let displayName = artist["display_name"] as? String
                        let type = artist["type"] as? String ?? "Unknown"
                        let agency = artist["agency"] as? String ?? "Unknown"
                        
                        print("✅ Successfully fetched artist by ID:")
                        print("   Name: \(name)")
                        if let displayName = displayName, displayName != name {
                            print("   Display Name: \(displayName)")
                        }
                        print("   Type: \(type)")
                        print("   Agency: \(agency)")
                        testResults["artistById"] = "Success: Found \(name)"
                    } else {
                        print("❌ No artist found with that ID")
                        testResults["artistById"] = "Failed: Artist not found"
                    }
                } catch {
                    print("❌ JSON parsing error: \(error)")
                    testResults["artistById"] = "Failed: JSON parsing error"
                }
            } else {
                print("❌ HTTP error: \(httpResponse.statusCode)")
                testResults["artistById"] = "Failed: HTTP \(httpResponse.statusCode)"
            }
        }
        semaphore.signal()
    }
    artistTask.resume()
    semaphore.wait()
} else {
    print("\n⏭️ Test 2: Skipped (no artist ID from Test 1)")
    testResults["artistById"] = "Skipped: No artist ID available"
}

// Test 3: Search artists by name
print("\n🔎 Test 3: Searching for 'BTS'...")
let searchURL = URL(string: "\(supabaseURL)/rest/v1/artists?name=ilike.*BTS*&select=*")!
var searchRequest = URLRequest(url: searchURL)
searchRequest.setValue(supabaseKey, forHTTPHeaderField: "apikey")
searchRequest.setValue("Bearer \(supabaseKey)", forHTTPHeaderField: "Authorization")
searchRequest.setValue("application/json", forHTTPHeaderField: "Accept")

let searchTask = URLSession.shared.dataTask(with: searchRequest) { data, response, error in
    if let error = error {
        print("❌ Error searching artists: \(error.localizedDescription)")
        testResults["search"] = "Failed: \(error.localizedDescription)"
    } else if let httpResponse = response as? HTTPURLResponse {
        print("📡 Response status: \(httpResponse.statusCode)")
        
        if httpResponse.statusCode == 200, let data = data {
            do {
                if let jsonArray = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                    print("✅ Search found \(jsonArray.count) results for 'BTS':")
                    testResults["search"] = "Success: \(jsonArray.count) results"
                    
                    for (index, artist) in jsonArray.enumerated() {
                        let name = artist["name"] as? String ?? "No Name"
                        let displayName = artist["display_name"] as? String
                        let type = artist["type"] as? String ?? "Unknown"
                        
                        print("   \(index + 1). \(name)")
                        if let displayName = displayName, displayName != name {
                            print("      Display: \(displayName)")
                        }
                        print("      Type: \(type)")
                    }
                } else {
                    print("❌ Invalid JSON format for search")
                    testResults["search"] = "Failed: Invalid JSON"
                }
            } catch {
                print("❌ JSON parsing error for search: \(error)")
                testResults["search"] = "Failed: JSON parsing error"
            }
        } else {
            print("❌ HTTP error for search: \(httpResponse.statusCode)")
            testResults["search"] = "Failed: HTTP \(httpResponse.statusCode)"
        }
    }
    semaphore.signal()
}
searchTask.resume()
semaphore.wait()

// Final Results Summary
print("\n📊 Test Results Summary:")
print(String(repeating: "=", count: 50))

for (test, result) in testResults {
    let status = (result as? String)?.hasPrefix("Success") == true ? "✅" : 
                (result as? String)?.hasPrefix("Skipped") == true ? "⏭️" : "❌"
    print("\(status) \(test): \(result)")
}

print("\n💡 Usage in your Swift code:")
print("""
// Fetch artist name by UUID
let artistName = try await databaseService.getArtistName(byId: artistUUID)

// Or use the convenience ArtistService
let artistService = ArtistService(databaseService: databaseService)
let name = try await artistService.getCachedArtistName(for: artistUUID)
""")

print("\n🎉 Artist fetching test completed!")