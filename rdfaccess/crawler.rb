   require 'rubygems'
   require 'json/pure'
   require 'uri'
   require 'time'
   require 'open-uri'
   require 'net/http'
#   require 'java'
   require 'date'
   require 'pp'
   require 'cgi'

   def header_from_url(url)

              useragent = "NotubeMiniCrawler/0.1"
              u =  URI.parse url  
              h = ""
              req = Net::HTTP::Get.new(u.request_uri,{'User-Agent' => useragent})
              begin    
                res2 = Net::HTTP.new(u.host, u.port).start {|http|h = http.head(u.request_uri).code }
              rescue Timeout::Error=>e
                puts "uri error #{e}"
              end

              return h
   end



   def do_dbp_lookups(desc)
     results = []
# look for likely things of interest in the description
     good_words = Array.new
     words = desc.scan(/(([A-Z]+[a-z]{3,}[ |,|.]){1,})/)
     words.each do |x|
       puts x[0]
       x[0].gsub!(/\.+$/,"")
       x[0].gsub!(/\s+$/,"")
       x[0].gsub!(/,+$/,"")
       good_words.push(x[0])
     end

# for each of these good_words, look for things in dbpedia
     good_words.each do |term_name|
       if term_name!=nil
         tn = term_name.gsub(/ /,"_")
         u2 = "http://dbpedia.org/page/#{tn}"
         u3 = "http://dbpedia.org/resource/#{tn}"
         #puts u2
         #check it exists
         r = header_from_url(u2.to_s)
         #add it to results if it does
         if(r && r=="200")
           results.push(u3.to_s)
         end
       end
     end
     return results;
   end


   def doQuery(serv,q)
        useragent = "NotubeMiniCrawler/0.1"
        z = serv + "?query=" + CGI.escape(q)
        u =  URI.parse z
        req = Net::HTTP::Get.new(u.request_uri,{'User-Agent' => useragent})
        req = Net::HTTP::Get.new( u.path+ '?' + u.query )
        req.basic_auth 'notube', 'ebuton'
        begin
          res2 = Net::HTTP.new(u.host, u.port).start {|http|http.request(req) }
        end
        r = ""
        begin
          r = res2.body
        rescue OpenURI::HTTPError=>e
          case e.to_s
            when /^404/
               raise 'Not Found'
            when /^304/

               raise 'Not Found'
            when /^304/  
               raise 'No Info'
          end
        end
        j = JSON.parse(r)
        return j
   end


#delete everything in the db
   def doDelete(filename)
        #it's easier just to delete the directory says damian
        Dir["#{File.dirname(filename)}/*"].each do |file|
           next if File.basename(file) == File.basename(filename)
           FileUtils.rm_rf file, :noop => true, :verbose => true
        end
        
   end


   def get_urls_to_retrieve(d1)
              urls = []

              if (d1==nil || d1 =="")
                 t = DateTime.now
                 d = t.strftime("%Y/%m/%d")
              else
                 d = d1
              end
              pt1 = "http://www.bbc.co.uk/"
              pt2 = "/programmes/schedules/"

              channel = "bbcone"
              url = "#{pt1}#{channel}#{pt2}london/#{d}.json"
              urls.push(url)

              channel = "bbctwo"
              url = "#{pt1}#{channel}#{pt2}england/#{d}.json"
              urls.push(url)

              channel = "bbcthree"
              url = "#{pt1}#{channel}#{pt2}#{d}.json"
              urls.push(url)

              channel = "bbcfour"
              url = "#{pt1}#{channel}#{pt2}#{d}.json"
              urls.push(url)

              channel = "bbchd"
              url = "#{pt1}#{channel}#{pt2}#{d}.json"
              urls.push(url)

              channel = "cbeebies"
              url = "#{pt1}#{channel}#{pt2}#{d}.json"
              urls.push(url)

              channel = "cbbc"
              url = "#{pt1}#{channel}#{pt2}#{d}.json"
              urls.push(url)

              channel = "parliament"
              url = "#{pt1}#{channel}#{pt2}#{d}.json"
              urls.push(url)

              channel = "bbcnews"
              url = "#{pt1}#{channel}#{pt2}#{d}.json"
              urls.push(url)

              channel = "radio4"
              url = "#{pt1}#{channel}#{pt2}fm/#{d}.json"
              urls.push(url)

              channel = "radio1"
              url = "#{pt1}#{channel}#{pt2}england/#{d}.json"
              urls.push(url)

              channel =  "1extra"
              url = "#{pt1}#{channel}#{pt2}#{d}.json"
              urls.push(url)

              channel =  "radio2"
              url = "#{pt1}#{channel}#{pt2}#{d}.json"
              urls.push(url)

              channel =  "radio3"
              url = "#{pt1}#{channel}#{pt2}#{d}.json"
              urls.push(url)

              channel = "5live" 
              url = "#{pt1}#{channel}#{pt2}#{d}.json"
              urls.push(url)

              channel =  "5livesportsextra"
              url = "#{pt1}#{channel}#{pt2}#{d}.json"
              urls.push(url)

              channel =  "6music"
              url = "#{pt1}#{channel}#{pt2}#{d}.json"
              urls.push(url)

              channel =  "asiannetwork"
              url = "#{pt1}#{channel}#{pt2}#{d}.json"
              urls.push(url)

              channel =  "worldservice"
              url = "#{pt1}#{channel}#{pt2}#{d}.json"
              urls.push(url)

              return urls
   end

   def get_single_url(url)

              useragent = "NotubeMiniCrawler/0.1"
              u =  URI.parse url  
              req = Net::HTTP::Get.new(u.request_uri,{'User-Agent' => useragent})
              begin    
                res2 = Net::HTTP.new(u.host, u.port).start {|http|http.request(req) }
              end

              r = ""
              begin
                 r = res2.body
              rescue OpenURI::HTTPError=>e
                 case e.to_s        
                    when /^404/
                       r = ""
                       raise 'Not Found'
                    when /^304/
                       r = ""
                       raise 'No Info'
                    end
              end
              return r
   end


#primarily to use our serlet-based jena data accessor
   def post_single_url(url,serv,q)

              useragent = "NotubeMiniCrawler/0.1"
              u =  URI.parse serv  
              req = Net::HTTP::Post.new(u.request_uri,{'User-Agent' => useragent})
              if(q)
                req.set_form_data({'url'=>url, "q"=>q}, ';')
              else
                req.set_form_data({'url'=>url}, ';')
              end
              req.basic_auth 'notube', 'ebuton'

              begin    
                res2 = Net::HTTP.new(u.host, u.port).start {|http|http.request(req) }
              end

              r = ""
              begin
                 r = res2.body
              rescue OpenURI::HTTPError=>e
                 case e.to_s        
                    when /^404/
                       raise 'Not Found'
                    when /^304/
                       raise 'No Info'
                    end
              end
              return r
   end


   def get_urls(url, d)
              useragent = "NotubeMiniCrawler/0.1"
              u =  URI.parse url  
              req = Net::HTTP::Get.new(u.request_uri,{'User-Agent' => useragent})
              begin    
                res2 = Net::HTTP.new(u.host, u.port).start {|http|http.request(req) }
              end
              j = nil
              begin
                 j = JSON.parse(res2.body)
              rescue JSON::ParserError=>e
                 puts "Error "+e.to_s
                 return Array.new
              rescue OpenURI::HTTPError=>e
                 case e.to_s        
                    when /^404/
                       raise 'Not Found'
                    when /^304/
                       raise 'No Info'
                    end
                 return Array.new
              end
              txt = ""
              service=j["schedule"]["service"]["key"]
              serviceTitle=j["schedule"]["service"]["title"]
              arr = j["schedule"]["day"]["broadcasts"]
              arr2 = Array.new
              pids = Array.new
              arr.each do |x|
                  pid = x["programme"]["pid"]
                  tt1 = x["programme"]["display_titles"]["title"]
                  tt2 = x["programme"]["display_titles"]["subtitle"]
                  pidTitle = "#{tt1}: #{tt2}"
                  # fix up &amps;
                  pidTitle.gsub!("&","&amp;")
                  startd = x["start"]
                  endd = x["end"]
                  #puts ".. #{startd} ,, #{d} ''"
                  if (startd.match(d))
                    pids.push(pid)
                    arr2.push({"pid"=>pid,"displayTitle"=>pidTitle,"startd"=>startd,"endd"=>endd,"service"=>service,"serviceTitle"=>serviceTitle})
                  end
              end
              return arr2,pids
   end

   def process_urls(arr)
              progs = []
              arr.each do |k|
                  start = k["start"]
                  ss = DateTime.parse(start) 
                  #res.body = url+" "+start+" \n"
                  finish = k["end"]
                  ff = DateTime.parse(finish) 
                  prog = k["programme"]["pid"]
                  progs.push(prog)
              end
              return progs
   end

   def save(dir, data, filename)
            FileUtils.mkdir_p dir
            fn = dir+"/"+filename 
            puts fn
            open(fn, 'w') { |f|
              f.puts data
              f.close
            }
   end


   begin

     base = "http://www.bbc.co.uk/"

# generate the rdf and save to a file?
     rdf = "<?xml version=\"1.0\" encoding=\"utf-8\"?>
<rdf:RDF xmlns:rdf      = \"http://www.w3.org/1999/02/22-rdf-syntax-ns#\"
         xmlns:rdfs     = \"http://www.w3.org/2000/01/rdf-schema#\"
         xmlns:po       = \"http://purl.org/ontology/po/\"
         xmlns:time     = \"http://www.w3.org/2006/time#\"
         xmlns:dc       = \"http://purl.org/dc/elements/1.1/\"
         xmlns:timeline = \"http://purl.org/NET/c4dm/timeline.owl#\"
         xmlns:event    = \"http://purl.org/NET/c4dm/event.owl#\">
"

     rdfsubjects = "<?xml version=\"1.0\" encoding=\"utf-8\"?>
<rdf:RDF xmlns:rdf      = \"http://www.w3.org/1999/02/22-rdf-syntax-ns#\"
         xmlns:rdfs     = \"http://www.w3.org/2000/01/rdf-schema#\"
         xmlns:po       = \"http://purl.org/ontology/po/\"
>
"

     #delete *everything*

#    serv = "http://dev.notu.be/2010/02/recommend/query"
     doDelete("DataStore")

     urls =  get_urls_to_retrieve(nil)
     puts urls

#    urls     =["http://www.bbc.co.uk/bbcone/programmes/schedules/london/2010/03/01.json","http://www.bbc.co.uk/bbctwo/programmes/schedules/england/2010/07/24.json"]

     arrs = Array.new
     allprogs = Array.new
     t = DateTime.now
     d = t.strftime("%Y-%m-%d")
#    d = "2010-03-01"
     urls.each do |u|
        arr,pids = get_urls(u,d)
        puts "sleeping 2 #{u} ... #{arr.class}"
        sleep 2
        arrs.push(pids)
        allprogs.push(arr)
     end

     allpids = arrs.flatten
     puts "foo #{allprogs}"
     puts "d #{d}"
     save("crawler/#{d.to_s}", allpids,"pids.txt")     


     allprogs.each do |progs|
       #puts "arr? #{progs.class}"
         if progs!=nil
           progs.each do |prog|
             #puts "arr?? #{prog.class}"
             pid = prog["pid"]
             displayTitle = prog["displayTitle"]
             startd = prog["startd"]
             startdd = startd.gsub(/T\d\d:\d\d:\d\dZ/,"")
#T15:00:00+01:00
             startdd = startd.gsub(/T\d\d:\d\d:\d\d[+|-]\d\d:\d\d/,"")
             endd = prog["endd"]
             service = prog["service"]
             serviceTitle = prog["serviceTitle"]
             rdfpart = "
<po:FirstBroadcast>
  <po:schedule_date rdf:datatype=\"http://www.w3.org/2001/XMLSchema#date\">#{startdd}</po:schedule_date>
  <event:time>
    <timeline:Interval>
      <timeline:start rdf:datatype=\"http://www.w3.org/2001/XMLSchema#dateTime\">#{startd}</timeline:start>
      <timeline:end rdf:datatype=\"http://www.w3.org/2001/XMLSchema#dateTime\">#{endd}</timeline:end>
    </timeline:Interval>
  </event:time>
  <po:broadcast_on rdf:resource=\"http://www.bbc.co.uk/programmes/#{service}#service\"/>
  <po:broadcast_of rdf:resource=\"http://www.bbc.co.uk/programmes/#{pid}#programme\"/>
  <dc:title>#{displayTitle}</dc:title>
</po:FirstBroadcast>
  <po:Masterbrand rdf:about=\"http://www.bbc.co.uk/programmes/#{service}#service\">
     <dc:title>#{serviceTitle}</dc:title>
  </po:Masterbrand>
"    
             rdf = rdf + rdfpart
           end
        end
     end
     
     puts "sleeping 1 then getting the data"
     sleep 1

     # now get the urls
     serv = "http://dev.notu.be/2010/02/recommend/query"
     allpids.each do |pid|
        if (pid && pid!="")
          begin
            puts "sleeping 2 #{pid}"
            sleep 2
            st = "http://www.bbc.co.uk/programmes/#{pid}.rdf"
            puts "getting #{st}"
# now using our servlet
            u = st.gsub(".rdf","#programme")
            q = "select ?v where {<#{u}> <http://purl.org/ontology/po/version> ?v}"
            data = post_single_url(st,serv,q)
#            puts "... #{data}"
            j = nil
            begin
              j = JSON.parse(data)
#             puts j
# we shoudl have some versions returned from teh query
# then post those too
              if(j.length > 1)
                versions = j[1]
                versions.each do |v|
                   z = v["v"]
                   puts "VVV #{z}"
                   sleep 2
                   uu = z.gsub("#programme",".rdf")
                   data = post_single_url(uu,serv,nil)
                end
              end      

            rescue JSON::ParserError=>e
              puts "posting failed #{e}"
            end


          rescue Exception=>e
            puts "Error #{e}"
          end
#possibly here: do a query for the genres and a google lookup
# using get_single_url and then parsing the json
# and then inserting 
# <po:subject rdf:resource="/programmes/subjects/adolescence#subject"/> 
# about the programme
# we could try genre and format too
# we could then either look it up as rdf or try the google approach
# rdf seems as good as anything
# we look for the sameas

          q = "select ?subject where 
{<http://www.bbc.co.uk/programmes/#{pid}#programme> <http://purl.org/ontology/po/subject> ?subject } "

#{<http://www.bbc.co.uk/programmes/#{pid}#programme> <http://purl.org/ontology/po/genre> ?subject } union
#{<http://www.bbc.co.uk/programmes/#{pid}#programme> <http://purl.org/ontology/po/format> ?subject }
#}
#"
          serv = "http://dev.notu.be/2010/02/recommend/query"
          print q
          result = doQuery(serv,q)

          rdfsubjects="#{rdfsubjects}
<rdf:Description rdf:about=\"http://www.bbc.co.uk/programmes/#{pid}#programme\">"

          if (result && result.length > 1)
            if (result[1] && result[1].length > 0)
              dbp1 =  result[1][0]["subject"]
              dbp1.each do |subs|
                rdfsubjects = "#{rdfsubjects}
<po:subject rdf:resource = \"#{subs}\"/>
"         
              end
            end
          end

#          puts "\nRES #{result}"

#          also do some grepping on the po:long_synopsis for potential 
#          dbpedia things:

          q = "select ?subject where { 
<http://www.bbc.co.uk/programmes/#{pid}#programme> <http://purl.org/ontology/po/medium_synopsis> ?subject 
}
"

          serv = "http://dev.notu.be/2010/02/recommend/query"
          print q
          result = doQuery(serv,q)
          puts "\nRES #{result}"
          dbp =  do_dbp_lookups(result[1][0]["subject"])
          dbp.each do |subs|
            rdfsubjects = "#{rdfsubjects}
<po:subject rdf:resource = \"#{subs}\"/>
"         
          end

          rdfsubjects = rdfsubjects + "</rdf:Description>\n"

        end
     end

     # save the schedule to the same directory
     rdf = rdf + "</rdf:RDF>\n"
     rdfsubjects = rdfsubjects + "</rdf:RDF>\n"

     # inject into rdfdb
     filen = "schedule.rdf"
     filens = "subjects.rdf"
     fullpath = "crawler/#{d.to_s}/data/#{filen}"
     fullpaths = "crawler/#{d.to_s}/data/#{filens}"
     save("crawler/#{d.to_s}/data", rdf,filen)
     save("crawler/#{d.to_s}/data", rdfsubjects,filens)

# now using our servlet
#leave this out for now
#     data = post_single_url(fullpath,serv,nil)   
#     puts "data #{data}"
#     j = nil
#     begin
#       j = JSON.parse(data)
#       puts j
#     rescue JSON::ParserError=>e
#       puts "posting failed[2] #{e}"
#     end

     data = post_single_url(fullpaths,serv,nil)   
     puts "data #{data}"
     j = nil
     begin
       j = JSON.parse(data)
       puts j
     rescue JSON::ParserError=>e
       puts "posting failed[2] #{e}"
     end


   end
