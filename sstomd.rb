
# Fetches the data for a ScholarSphere document in Fedora 3 and
# outputs it to Markdown. The actual content of the "content"
# and "thumbnail" datastreams is omitted but their structure 
# (aka fields) are included. 
require 'rubydora'

def print_obj(obj)

  puts "# #{obj.pid}"

  puts "# PROFILE"
  obj.profile.each do |k,v|
    puts "* **#{k}** #{v}"
  end
  puts 

  puts "# MODELS"
  obj.models.each do |model|
    puts "* #{model}"
  end
  puts 

  puts "# DATASTREAMS"
  obj.datastreams.each do |k,v|
    print_ds(obj, k) 
  end
  puts

end


def print_ds(obj, name)
  puts "## Datastream: #{name}"
  ds = obj.datastreams[name]
  puts "### Profile"
  ds.profile.each do |k,v|
    puts "* **#{k}** #{v}"
  end
  puts 

  ds.versions.each_with_index do |data, version|
    puts "### Version #{version}"
    if name == "content" || name == "thumbnail"
      puts "`(content omitted)`"
    else
      # http://stackoverflow.com/a/15401417/446681
      pretty_content = data.content.scan(/.{1,80}\W/).join(" ")
      puts "```\r\n#{pretty_content}\r\n```\r\n"
    end
    puts
  end
end

if ARGV[0] == nil
  puts "Syntax ruby sstomd.rb pid"
  puts 'where pid is something like "scholarsphere:123xyz"'
  exit 1
end

repo = Rubydora.connect :url => 'http://localhost:8983/fedora', 
  :user => 'fedoraAdmin', :password => 'fedoraAdmin'

pid = ARGV[0]
obj = repo.find(pid)
print_obj obj



