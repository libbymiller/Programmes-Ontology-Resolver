require 'time'
require 'date'
require 'uri'
require 'open-uri'
require 'net/http'
require 'cgi'

def get_single_url(url)

    u =  URI.parse url
    response = nil
    Net::HTTP.start(u.host, u.port) {|http|
      response = http.head(u.path+ '?' + u.query)
    }
    puts "URL is #{url}"
    return response.code

end

# Helper function from chapter 4.17: Randomizing an Array
#http://pleac.sourceforge.net/pleac_ruby/filecontents.html
def fisher_yates_shuffle(a)
    (a.size-1).downto(1) { |i|
        j = rand(i+1)
        a[i], a[j] = a[j], a[i] if i != j
    }
end


def dotest()
#read in the file
   d = DateTime.now
   dt = d.strftime("%Y-%m-%d")
   local_filename = "data/matchdata-#{dt}.txt"
   
#select random one

# Open the file, default mode is reading. Read all lines into an array.
   lines = File.open(local_filename).collect

# Shuffle them.
   fisher_yates_shuffle(lines)

# Print the shuffled lines.
   puts "Line found: #{lines[0]}"

#pick out the crid
   arr = lines[0].split("|")
   crid = arr[0]
# sometimes no crid - tes for this

#try them on the service
   u = "http://services.notu.be/resolve?"+CGI.escape("uri[]")+"=#{crid}"
   puts "Crid found #{crid}"

   result = get_single_url(u)

   alert="ok"

   if (result==404)
     alert="NOT ok"
   end

#let me know
   puts "Result: #{result} #{alert}"

end

dotest()
