import xmltree, xmlparser, httpclient, streams, sequtils

type Entry* = object
  id: string
  updated: string
  published: string
  title: string
  summary: string
  authors: seq[string]
  categories: seq[string]

type SearchTerms* = object
  title: seq[string]


proc build_search_string(terms: SearchTerms) : string =
  let title =
    if len(terms.title) > 0:
      "ti:" & foldr(terms.title, a & "+" & b)
    else:
      ""
  result = "http://export.arxiv.org/api/query?search_query=" & title

proc search*(terms: SearchTerms) : seq[Entry] =
  let search_string = build_search_string(terms)

  var entries : seq[Entry] = @[]

  let content = newStringStream(getContent(search_string))
  let doc = content.parseXML
  let elem = doc.findAll("entry")
  for entryXML in elem:
    let id = entryXML.child("id").innerText
    let updated = entryXML.child("updated").innerText
    let published = entryXML.child("published").innerText
    let title = entryXML.child("title").innerText
    let summary = entryXML.child("summary").innerText
    var authors : seq[string] = @[]
    let authorElements = entryXML.findAll("author")
    for authorElement in authorElements:
      authors.add(authorElement.child("name").innerText)
    let categoryElements = entryXML.findAll("category")
    var categories : seq[string] = @[]
    for categoryElement in categoryElements:
      categories.add(categoryElement.attr("term"))
    let entry = Entry(id: id, updated: updated, published: published, title: title, summary: summary, authors: authors, categories: categories)

    entries.add(entry)
  result = entries


if isMainModule:
  let terms = SearchTerms(title: @["filter", "mcmc"])
  let entries = search(terms)

  for entry in entries:
    echo "----------------"
    echo "Title: " & entry.title
    echo "Authors: " & entry.authors
    echo "Summary: " & entry.summary
    echo "Categories: " & entry.categories
