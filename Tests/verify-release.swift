import Foundation
import CryptoKit

// Verify a packaged release against the public key embedded in the app.
let feed = try XMLDocument(contentsOf: URL(fileURLWithPath: CommandLine.arguments[1]))
let enclosure = try feed.nodes(forXPath: "/rss/channel/item/enclosure").first as! XMLElement
let signature = enclosure.attributes!.first { $0.localName == "edSignature" }!.stringValue!
let archive = try Data(contentsOf: URL(fileURLWithPath: CommandLine.arguments[2]))
let plist = try Data(contentsOf: URL(fileURLWithPath: CommandLine.arguments[3]))
let info = try PropertyListSerialization.propertyList(from: plist, format: nil) as! [String: Any]
let key = try Curve25519.Signing.PublicKey(rawRepresentation: Data(base64Encoded: info["SUPublicEDKey"] as! String)!)
precondition(key.isValidSignature(Data(base64Encoded: signature)!, for: archive))
precondition(enclosure.attribute(forName: "length")!.stringValue == String(archive.count))
let item = try feed.nodes(forXPath: "/rss/channel/item").first as! XMLElement
let version = item.children!.first { $0.localName == "version" }!.stringValue!
precondition(version == info["CFBundleVersion"] as? String)
print("PASS: release archive signature, length, and bundle version")
