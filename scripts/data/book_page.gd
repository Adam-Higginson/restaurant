class_name BookPage
extends Resource
## One page of a [Book]: a heading, a few lines of text, and perhaps a small
## drawing under them. The [BookView] lays it out on the paper.

## The page's heading, set larger at the top. Can be empty.
@export var heading: String = ""
## The page's text, a paragraph a line.
@export_multiline var lines: PackedStringArray = PackedStringArray()
## A small drawing under the text, or null.
@export var picture: Texture2D = null


## A page headed [param page_heading] with [param page_lines] on it.
static func make(page_heading: String, page_lines: PackedStringArray) -> BookPage:
	var page: BookPage = BookPage.new()
	page.heading = page_heading
	page.lines = page_lines
	return page
