class_name Book
extends Resource
## A book you can read: its title and its pages, in order. Read in the
## [BookView], two pages at a time. A book can be a .tres file of its own, or
## made up as it's opened (the recipe book writes a page per recipe).

## What the book is called.
@export var title: String = ""
## The pages, first to last.
@export var pages: Array[BookPage] = []
