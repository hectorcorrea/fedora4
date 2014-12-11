RDF, Fedora, and ActiveFedora for relational heads
==================================================

Notes on my current understanding of how RDF, Fedora, and ActiveFedora compares to the components of a traditional application that uses Ruy on Rails with a relational database backend.


RDBMS concepts
--------------
Tables/columns/relationships

Book table:

    name    type
    -----   -------
    id      integer
    title   string
    isbn    string

Page table:

    name    type
    -----   -------
    id      integer
    book_id integer    (foreign key to books)
    number  integer
    text    string

And we use SQL to query and update:

    INSERT INTO books(id, title, isbn) VALUE (1, "Lord of the Rings", "123-456-789")
    INSERT INTO pages(id, book_id, number, text) VALUE (1, 1, 1, 'hi frodo')
    INSERT INTO pages(id, book_id, number, text) VALUE (2, 1, 2, 'dude is that mordor?')

    SELECT title, isbn FROM books WHERE title = 'lord of the rings'

    SELECT * FROM pages WHERE book_id = 2


Rails / ActiveRecord
--------------------
Assuming you have the tables described above you can define a couple of ActiveRecord classes in Rails to represent each table: 

    class Book < ActiveRecord::Base
      has_many :pages
    end

    class Page < ActiveRecord::Base
      belongs_to :book
    end

Notice the `has_many` and `belongs_to` to indicate the one-to-many relationship. Fields are not indicated on the class but they are automatically picked from the tables at runtime. 

You can access the database via ActiveRecord objects:

    # Create a new Book object
    b = Book.new
    b.title = "Lord of the Rings"
    b.isbn = "123-456-789"

    # Create a couple of page objects and add them to the book.pages collection.
    p1 = Page.new(number: 1, text: "hi frodo")
    b.pages < p1

    p2 = Page.new(number: 2, text: "dude, is that mordor?")
    b.pages < p2

    # Save the book object (will save both book and pages)
    b.save

    # Fetch the saved record
    b = Book.find(1)
    puts b.title              # => "Lord of the Rings"
    puts b.pages[0].text      # => "hi frodo"



Resource Description Framework (RDF)
------------------------------------
RDF is a W3C standard for data interchange on the Web (See http://www.w3.org/RDF)

There are no tables or columns in RDF. There are **triples** and **graphs**.

Triple is a three part statement that includes a *subject*, a *predicate*, and an *object*:

    book1    title       "Lord of the Rings"

There are many ways to represent RDF including N-Triples, Turtle, and RDF/XML. The examples below use N-Triples. Here is how the previous triple would look like in N-Triples.

    <book1> <title>     "Lord of the Rings"

A graph is a collection of triples:
          
    <book1> <title>   "Lord of the Rings"
    <book1> <isbn>    "123-456-789"
    <page1> <number>  "1"
    <page1> <text>    "hi frodo"
    <page2> <number>  "2"
    <page2> <text>    "dude, is that mordor?"
    <book1> <page>    "page1"
    <book1> <page>    "page2"

Ideally, subjects and predicates in a triple are URIs. 
Objects can also be URIs and that's a way to express relationships.

    <http://libraries.psu.edu/catalog/book1>        <title>   "Lord of the Rings"
    <http://libraries.psu.edu/catalog/book1/page1>  <number>  "1"
    <http://libraries.psu.edu/catalog/book1/page1>  <text>    "hi frodo"
    <http://libraries.psu.edu/catalog/book1/page2>  <number>  "2"
    <http://libraries.psu.edu/catalog/book1/page2>  <text>    "dude, is that mordor?"
    <http://libraries.psu.edu/catalog/book1>        <pages>   <http://libraries.psu.edu/catalog/book1/page1>    
    <http://libraries.psu.edu/catalog/book1>        <pages>   <http://libraries.psu.edu/catalog/book1/page2>    

Predicates (fields) should also be URIs so that things like `title` are not ambigous. 
For example we could have something like `<http://dublincode.org/metadata/title>` instead of `<title>`

A triple is roughly the equivalent of a cell (row/column) in a relational database (See http://workingontologist.org, page 31) 


Fedora 
------ 
Fedora is a document repository suited for large objects (e.g, text, images, audio and video files) and natively supports RDF to store metadata about these objects.

Fedora stands for Flexible Extensible Digital Object Repository Architecture. See http://www.fedora-commons.org/about

Fedora provides an HTTP API to create and update objects. 

For example, this request will create a new object in Fedora:

    HTTP POST http://localhost:8983/fedora/rest/book1

...and something like this will add a couple of "fields" to this new object:

    HTTP POST http://localhost:8983/fedora/rest/book1
    content-body
        <> <http://whatever/title> "Lord of the Rings"
        <> <http://whatever/isbn> "978-0618640157"

See `book_demo.rb` at https://github.com/hectorcorrea/fedora4 for an example of this.



Rails/ActiveFedora
------------------
ActiveFedora is a Ruby gem that does for Fedora what ActiveRecord does for relational databases. This means that we can define a class as follow:

    class BookObject < ActiveFedora::Base
      property :title, predicate: ::RDF::DC.title
      property :isbn, predicate: ::RDF::URI.new('http://libraries.psu.edu/metadata/isbn')
    end

...and then create and fetch data using code as follows:

    # Create an object...
    b = BookObject.new( title: ["Lord of the Rings"], isbn: ["123-456-789"] )
    b.save
    puts b.id       # => "123"

    # ...and fetch it
    b = BookObject.find("123")
    puts b.title     # => "Lord of the Rings"
    puts b.isbn      # => "123-456-789"

ActiveFedora automatically adds a property `hasModel` to the Fedora object to represent what Ruby class this object should be serialized into when it's fetched. That's how `b.title` and `b.isbn` were populated in the previous example. 

Notice that we do specify the fields (predicates) in our ActiveFedora models. This is because there is no table with a specific structure in Fedora where Rails could pick them up as ActiveRecord does for relational databases.

You can also define relationships like the one between Books and Pages.

Behind the scenes ActiveFedora uses ActiveTriples to handle triples and LDP to handle the HTTP communication to Fedora. 


ScholarSphere and Fedora
------------------------
A peak inside a GenericFile object in Fedora 3. 

    https://gist.github.com/hectorcorrea/f1057f47fdaf33e39210


The end
-------
.
.
.
.
.
.
.
.
.



Misc
----
Creating the RDBMS Rails project 

    rails new library
    cd library
    rails generate scaffold book title:string isbn:string
    rails generate model page number:integer text:text book:references
    rake db:migrate
    rails s





