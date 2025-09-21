#!/usr/bin/env swift

import Foundation

// Test RSS feed fetching
let rssURL = URL(string: "https://www.soompi.com/feed/")!

print("🔍 Testing RSS feed from Soompi...")

let task = URLSession.shared.dataTask(with: rssURL) { data, response, error in
    if let error = error {
        print("❌ Error fetching RSS: \(error)")
        exit(1)
    }

    guard let httpResponse = response as? HTTPURLResponse else {
        print("❌ Invalid response type")
        exit(1)
    }

    print("✅ HTTP Status: \(httpResponse.statusCode)")

    if let data = data {
        print("📊 Data received: \(data.count) bytes")

        // Try to parse as XML
        let parser = XMLParser(data: data)
        var itemCount = 0

        class RSSDelegate: NSObject, XMLParserDelegate {
            var itemCount = 0

            func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
                if elementName == "item" {
                    itemCount += 1
                }
            }
        }

        let delegate = RSSDelegate()
        parser.delegate = delegate

        if parser.parse() {
            print("✅ RSS parsed successfully")
            print("📰 Found \(delegate.itemCount) news items")
        } else {
            print("❌ Failed to parse RSS")
            if let error = parser.parserError {
                print("   Error: \(error)")
            }
        }
    }

    exit(0)
}

task.resume()
RunLoop.main.run()