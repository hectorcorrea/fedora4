# The simplest example to write an object it Fedora 3 using Rubydora.
require 'rubydora'
url = 'http://localhost:8983/fedora'
user = 'fedoraAdmin'
password = 'fedoraAdmin'

repo = Rubydora.connect :url => url, :user => user, :password => password 
obj = repo.find_or_initialize('test:1111')
obj.save
print obj
