A set of very basic demos using the Fedora 4 HTTP API from Ruby.

I wrote this code as I experiment with Fedora 4 in order to help me learn how Fedora 4 works. In the process I had to learn a little bit about RDF triples and SparQL. In has been a fun experiment and I hope it helps others that want to peek behind the curtain on how Fedora REST API works.

This code goes straight from Ruby to Fedora via HTTP without using any external gems. It is as bare-bones as it gets and might be helpful to learn how the Fedora HTTP API works, but it is not production ready. This is just a learning tool. 


Requirements
------------
You need to have a running instance of Fedora 4 already in your system for these examples to work. 

*If you don't have a running version of Fedora*
  * Download the one-click-war from https://wiki.duraspace.org/display/FF/Downloads 
  * Run it via `open name-of-war-file.war` (You need Java installed for this to run)
  * Click "Start" on the prompt to start Fedora. By default Fedora will listen on port 8080. 
  * At this point you should be able to go browse to http://localhost:8080/rest/ and see the the Fedora web interface.

If you are using Fedora from the Hydra-Jetty just make sure it is running. 

Some of the code examples in this repo point to port 8080 (the default Fedora port) and others to port 8983 (the default port when running under Jetty). You might need to tweak these values in the code to match your configuration.


Code Examples
-------------
* `fedora_explorer.rb` shows how to fetch the metadata for all the objects in a Fedora 4 repository. This is a basic example on how to walk the tree of nodes.


* `fedora_api.rb, fedora_doc.rb, and demo.rb,` are a set of programs that I wrote to test the Fedora HTTP API when it was in Beta. I do not know how well they run with the release version of Fedora, use at your own risk! 

`demo.rb` runs through the most basic functionality. It creates a new RDF source in Fedora, fetches it, then adds a non-RDF source (e.g. file content) to it, fetches the content, adds a new field to the RDF source, and then updates it. After running the demo you should be able to go back to http://localhost:8080/rest/ and see your new document. The demo creates a new object everytime you run it, the name of the document is a timestamped and looks like this: "Sample object created at 2014-08-21 09:15:45 -0400"


Other Resources
---------------
Fedora 4 REST API documentation: https://wiki.duraspace.org/display/FF/RESTful+HTTP+API

There are many other higher level Ruby gems to work with Fedora 4 that are **much better** than the code in this repo, in particular take a look at [ActiveTriples](https://github.com/ActiveTriples/ActiveTriples) and [ActiveFedora](https://github.com/projecthydra/active_fedora). 

The `testdrive` repo by ecowles at https://github.com/escowles/testdrive has a great demo on how to get started with those gems.

