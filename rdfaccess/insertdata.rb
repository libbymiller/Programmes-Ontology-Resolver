require 'rubygems'
require 'json/pure'
require 'net/http'
require 'uri'
require 'cgi'


def findMatches(data)

# assumes one channel
  chan = nil
  txtresults = ""
  errors = ""
  results = "<rdf:RDF xmlns:rdf ='http://www.w3.org/1999/02/22-rdf-syntax-ns#' xmlns:owl='http://www.w3.org/2002/07/owl#'>"

  channels ={"BBC ONE"=>"bbcone", "BBC TWO"=>"bbctwo", "BBC THREE"=>"bbcthree", "BBC FOUR"=>"bbcfour", "CBBC Channel"=>"cbbc", 
"CBeebies"=>"cbeebies","parliament"=>"BBC Parliament","BBC NEWS"=>"bbcnews", 
"BBC Red Button"=>"redbutton", "BBC R5L"=>"5live","BBC R5SX"=>"5livesportsextra","BBC 6 Music"=>"6music","BBC Radio 7"=>"radio7", "BBC R1X"=>"1xtra",
"BBC Asian Net."=>"asiannetwork", "BBC World Sv."=>"worldservice","BBC Radio 1"=>"radio1",
"BBC Radio 2"=>"radio2","BBC Radio 3"=>"radio3","BBC Radio 4"=>"radio4/fm"}


  arr = data.split("\n")
  #puts arr.length
  arr.each do |row|
  puts "row...#{row},,,"
  rs = row.split("|")
  puts "length... #{rs.length}"
      
    if(rs && rs.length>3)
  #split it into components by tab: crid, dvb, start, end, channel, title
      crid = rs[0]
      dvb = rs[1]

    # formatting of dates?
      st = rs[2]
      en = rs[3]
      ch = rs[4]

      ch = channels[ch.to_s]
      chan = ch
      puts "channel ... #{ch}"

      ti = rs[5]
      da = st.gsub(/T\d\d:\d\d.*/,"")
      # should check channel is in the list

      #now try to find a pid have a controlled list of channels for now.
      #these could be from the dvb eventually

      if ch=="bbcone" || ch=="bbctwo" 

        q = " PREFIX xsd: <http://www.w3.org/2001/XMLSchema#> 
select distinct ?pid ?prog ?title where { ?p 
<http://purl.org/ontology/po/schedule_date> \"#{da}\"^^xsd:date . ?p 
<http://purl.org/ontology/po/broadcast_on> ?service . ?service 
<http://purl.org/ontology/po/parent_service> 
<http://www.bbc.co.uk/services/#{ch}#service> . ?p 
<http://purl.org/NET/c4dm/event.owl#time> ?t . ?t 
<http://purl.org/NET/c4dm/timeline.owl#start> ?s . ?t 
<http://purl.org/NET/c4dm/timeline.owl#end> ?e . ?p 
<http://purl.org/ontology/po/broadcast_of> ?pid . ?prog 
<http://purl.org/ontology/po/version> ?pid . ?prog 
<http://purl.org/ontology/po/short_synopsis> ?title . FILTER( (?s = 
\"#{st}\"^^xsd:dateTime ))
}"

# && (?e = \"#{en}\"^^xsd:dateTime ) )

      else
        q = " PREFIX xsd: <http://www.w3.org/2001/XMLSchema#> 
select distinct ?pid ?prog ?title where { ?p 
<http://purl.org/ontology/po/schedule_date> \"#{da}\"^^xsd:date . ?p 
<http://purl.org/ontology/po/broadcast_on>  
<http://www.bbc.co.uk/services/#{ch}#service> . ?p 
<http://purl.org/NET/c4dm/event.owl#time> ?t . ?t 
<http://purl.org/NET/c4dm/timeline.owl#start> ?s . ?t 
<http://purl.org/NET/c4dm/timeline.owl#end> ?e . ?p 
<http://purl.org/ontology/po/broadcast_of> ?pid . ?prog 
<http://purl.org/ontology/po/version> ?pid . ?prog 
<http://purl.org/ontology/po/short_synopsis> ?title . FILTER( (?s = 
\"#{st}\"^^xsd:dateTime ) )
}"
#&& (?e = \"#{en}\"^^xsd:dateTime ) )

      end

      # make the query
 
      serv = "http://dev.notu.be/2010/02/recommend/query"
      result = doQuery(serv,q)

      pid = nil
      title = nil
      puts "result #{result}"
      puts "length #{result.length}"
      if(result.length > 0)
       
         versions = result[1]
         #puts versions
         versions.each do |v|
           pid = v["pid"]
           title = v["title"]
         end
      else
         result = doQuery(serv,q)
         if(result.length > 0)
       
           versions = result[1]
           #puts versions
           versions.each do |v|
             pid = v["pid"]
             title = v["title"]
           end
         else
           errors = "#{errors}
#{row}"
         end

      end
    # if we get more than one result, check on the title
    #...
    # create the sameas matches in rdf
      if(pid!=nil && pid!="" && crid && crid!="")
         progsurl = pid
       # add to the text rdf to add
         puts "CRID OK"
         results = "#{results}
<rdf:Description rdf:about='#{crid}'>
  <owl:sameAs rdf:resource='#{progsurl}'/>
</rdf:Description>
"
#also the channels and data sameas (do the channels separately)
        txtresults = "#{txtresults}
<#{crid}> <#{progsurl}> #{title}"
         if dvb && dvb!=""
            puts "DVB OK"
            results = "#{results}
<rdf:Description rdf:about='#{crid}'>
  <owl:sameAs rdf:resource='#{dvb}'/>
</rdf:Description>
"
           txtresults = "#{txtresults}
<#{crid}> <#{dvb}> #{title}"

         end
      end
    end
  end
  return "#{results}\n</rdf:RDF>",txtresults,errors,chan

end
       
def doQuery(serv,q)
  useragent = "NotubeMiniCrawler/0.1"
  puts q
  z = serv + "?query=" + CGI.escape(q)
  u =  URI.parse z
  req = Net::HTTP::Get.new(u.request_uri,{'User-Agent' => useragent})

  req = Net::HTTP::Get.new( u.path+ '?' + u.query ) 

  req.basic_auth 'notube', 'notube'
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
  j = JSON.parse(r)
  return j
#  return "b00stbbh"
end


#primarily to use our serlet-based jena data accessor
def post_single_url(url,serv,q,variable_name,usr,pass)

              useragent = "NotubeMiniCrawler/0.1"
              u =  URI.parse serv  
#              req = Net::HTTP::Post.new(u.request_uri,{'User-Agent' => useragent})
              puts "posting to #{serv} variable_name #{variable_name}"
              if (u.query)
                req = Net::HTTP::Post.new(u.path+ '?' + u.query,{'User-Agent' => useragent})
              else
                req = Net::HTTP::Post.new(u.path,{'User-Agent' => useragent})
              end
              if(variable_name)
                req.set_form_data({variable_name=>q}, ';')
              else
                req.set_form_data({'url'=>url}, ';')
              end
              req.basic_auth usr,pass

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


def save(dir, data, filename)
            FileUtils.mkdir_p dir
            fn = dir+"/"+filename 
            open(fn, 'w') { |f|
              f.puts data
              f.close
            }
end


def go(data)   
 result = "ok"

#  data = "crid://foobar	dvb://foobar	2010-06-14T18:00:00	2010-06-14T18:35:00	bbcone	BBC News 
#crid://foobar1	dvb://foobar1	2010-06-14T19:00:00	2010-06-14T19:35:00	bbc2	Something Else "
#  data = "crid://fp.bbc.co.uk/5a6s2e	dvb://3098.1041.1041.233a.dvb.tvdns.net	2010-06-20T00:40:00+01:00	2010-06-20T00:45:00+01:00	bbcone	Weatherview
#	dvb://3098.1041.1041.233a.dvb.tvdns.net	2010-06-20T00:45:00+01:00	2010-06-20T06:00:00+01:00	bbcone	BBC News"

  rdf,txtresults,errors,chan =  findMatches(data)
# puts rdf
  puts txtresults
# now post these to the right url

# for the rdf
  t = DateTime.now
  d = t.strftime("%Y/%m/%d")

  if(chan==nil)
    chan=""
  end
  chan = chan.gsub("/","_")

  filen = "#{chan}sameas.rdf"
  fullpath = "crawler/#{d.to_s}/data/#{filen}"
  save("crawler/#{d.to_s}/data", rdf,filen)

  puts "ERRRORS #{errors}"

  save("crawler/#{d.to_s}/data", errors,"notmatched.txt")
   
# now using our servlet
  serv = "http://dev.notu.be/2010/02/recommend/query"
  data = post_single_url(fullpath,serv,nil,nil,"notube","ebuton")
  puts "data #{data}"
  j = nil    
  begin       
    j = JSON.parse(data)
    puts j
  rescue JSON::ParserError=>e
    puts "posting failed[2] #{e}"
    result = "not ok"
  end

  #also post to sameas.
  puts "posting sameas data"
  txtresults = "#{txtresults}\n"
  puts txtresults
  data2 = post_single_url("","http://notube.rkbexplorer.com/crs/assert/?action=post",txtresults,"data","notube","notube")

  puts "result is #{data2}"
  return  result
end
    
