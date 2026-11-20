// SPDX-License-Identifier: Apache-2.0
import SwiftHTML

let document = try HTMLDocument.parseFragment("<p>Grüße 🌍 &amp; Swift</p>")
let paragraph = try document.select("p").first!
let text = try paragraph.text()
precondition(text == "Grüße 🌍 & Swift")
print("macOS deployment consumer passed")
