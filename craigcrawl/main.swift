#!/usr/bin/swift

import Foundation

class Crawler:AnyObject {
	var baseStr = "https://newyork.craigslist.org/search/zip?query="
	
	var visited:Set<URL> = []
	var toVisit:Set<URL> = []
	var matching:Set<URL> = []
	let maxPages = 200
	let semaphore = DispatchSemaphore(value: 0)
	var searchTerm:String = ""
	
	func start(withSearchTerm:String){
		baseStr.append(withSearchTerm)
		self.searchTerm = withSearchTerm
		self.toVisit.insert(URL(string: baseStr)!)
		self.crawl()
		self.semaphore.wait()
	}
	
	func crawl() {
		guard visited.count <= maxPages else {
			print("Reached max number of pages to visit")
			for i in matching {
				print("Pages with desired terms = \(i)")
			}
			semaphore.signal()
			return
		}
		guard let pageToVisit = toVisit.popFirst() else {
			print("🏁 No more pages to visit")
			for i in matching {
				print("Pages with desired terms = \(i)")
			}
			semaphore.signal()
			return
		}
		if visited.contains(pageToVisit) {
		print("visited contains pageToVisit: \(pageToVisit)")
			crawl()
		} else {
		print(">>>>>>>> #1. not a redundant search: visit(page: pageToVisit: \(pageToVisit)")
			visit(page: pageToVisit)
		}
	}
	
	func visit(page url: URL) {
		print(">>>>>>>> about to insert url \(url)")

		visited.insert(url)
		
		let task = URLSession.shared.dataTask(with: url) { data, response, error in
			defer { self.crawl(); print("defer crawl") }
			guard
				let data = data,
				error == nil,
				let document = String(data: data, encoding: .utf8) else { return }
//			self.parse(document: document, url: url, searchTerm: )
			print(">>>>>>>> #3. about to parse")
			self.parse(document: document, url: url, searchTerm: self.searchTerm)
		}
		
		print(">>>>>>>> #2. Visiting page: \(url)")
		task.resume()
	}
	
	func parse(document: String, url: URL, searchTerm:String) {
		
		func find(word: String) {
			if document.contains(word) {
				print(">>>>>>>> Word '\(word)' found at page \(url)")
				matching.insert(url)
			}
		}
		
		func collectLinks() -> [URL] {
			func getMatches(pattern: String, text: String) -> [String] {
			print(">>>>>>>> #5. get matches(text")
				// used to remove the 'href="' & '"' from the matches
				func trim(url: String) -> String {
					return String(url.characters.dropLast()).substring(from: url.index(url.startIndex, offsetBy: "href=\"".characters.count))
				}
				
				let regex = try! NSRegularExpression(pattern: pattern, options: [.caseInsensitive])
				let matches = regex.matches(in: text, options: [.reportCompletion], range: NSRange(location: 0, length: text.characters.count))
				return matches.map { trim(url: (text as NSString).substring(with: $0.range)) }
			}
			
			let pattern = "href=\"(http://.*?|https://.*?)\""
			let matches = getMatches(pattern: pattern, text: document)
			return matches.flatMap { URL(string: $0) }
		}
			find(word: searchTerm)
			print(">>>>>>>> #4. about to collect links after searching for term")
		collectLinks().forEach {
			if $0.absoluteString.contains("newyork.craigslist.org") && !$0.absoluteString.contains("blog") && !$0.absoluteString.contains("forum") && !$0.absoluteString.contains("about") {
				print(">>>>>>>> $0 = \($0)")
				toVisit.insert($0)
			}
//		toVisit.insert($0)
		
		print("inside collectLinks.forEach")
		}
	}
}

let b = dump(CommandLine.arguments)
let a = Crawler()
for i in 1..<b.count {
	print("number \(b[i])")
	a.start(withSearchTerm: b[i])
//print(b[i])
}
	
