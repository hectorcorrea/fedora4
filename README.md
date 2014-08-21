A set of very basic demos using the Fedora 4 HTTP API from Ruby.


Requirements
------------
These demos have been tested with Fedora 4 beta 01. 

* Download `fcrepo-webapp-4.0.0-beta-01-jetty-console.war` from https://github.com/fcrepo4/fcrepo4/releases
* Run it via `open fcrepo-webapp-4.0.0-beta-01-jetty-console.war` (You need Java 8 installed for this to run)
* Click "Start" on the prompt to start Fedora. By default Fedora will listen on port 8080. 

At this point you should be able to go browse to http://localhost:8080/rest/ and see the the Fedora web interface.


Demo
----
There is a demo program that runs through the most basic functionality. It creates a new Fedora object, fetches it, then adds a datastream to it, fetches the datastream, and runs a Fixity check on it.

To run the demo do:

	ruby demo.rb

After running the demo you should be able to go back to http://localhost:8080/rest/ and see your new document. The demo creates a new object everytime you run it, the name of the document is a timestamped and looks like this: "Sample object created at 2014-08-21 09:15:45 -0400"


The code
--------
* demo.rb is just that, a small demo of the basic functionality.
* fedora_api.rb is a wrapper for the Fedora HTTP API.
* fedora_doc.rb is a small helper class to convert an HTTP response from fedora_api into a Fedora document with fields like "location" and "body"
* furl.rb is a small program to interface with fedora_api. A joke of a "cURL for Fedora"


Other Resources
---------------
For a much more comprehensive sample of how to work with Fedora from Ruby take a look at Rubydora https://github.com/projecthydra/rubydora

