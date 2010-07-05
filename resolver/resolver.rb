      require 'date'
      require 'uri'
      require 'cgi'
      require 'open-uri'
      require 'net/http'
      require 'rubygems'
      require 'json/pure'
      require 'pp'


      def resolve(req, res)
        res['Content-Type'] = 'text/javascript'
        res.status = 404
        pp req.query_string

        uris = []

# different types of uris
        crid=nil
        dvb=nil
        prog = nil
        pips = nil        

# other parameters
        start=nil
        startt = req.query["start"]
        utc = startt
        # make sure that start is in utc
        if startt
          if  startt.match(/Z$/)
            #ok. but since we store as local time we need to convert it
             ts = Time.parse(startt)
             # check if date indicates daylight savings time

             # this is messy. our db stores the times as it finds them 
             # which is Z if in UTC, or +01:00 if in BST

             t = Time.now
             if t.utc?
               utc = ts.utc.xmlschema()
             else
               ts = ts - 3600
               utc = ts.getlocal.xmlschema()
               utc = utc.gsub(/Z$/,"+01:00") #ugh but I can't see another way
               utc = utc.gsub(/\+00:00$/,"+01:00") #ugh but I can't see another way
             end
          else
            err =  "Error - start time should be in UTC"
            result=["404",err]
            res.body = JSON.pretty_generate(result)
            return
          end
        end

        warnings = ""
        duration = nil
        duration = req.query["duration"]
        if(duration)
          warning = "#{warning}
Duration is not yet supported"
        end
        transmissionTime = nil
        transmissionTime = req.query["transmissionTime"]
        if(transmissionTime)
          warning = "#{warning}
transmissionTime is not yet supported"
        end

        eventid=nil
        eventid = req.query["eventid"]
        serviceid=nil
        serviceid = req.query["serviceid"]
        fmt = nil
        fmt = req.query["fmt"]

        # webrick won't let you have two parameters with the same name
        qs = req.query_string.to_s.split("&")
        qs.each do |q|
           r = q.split("=")
           k = r[0]
           v = r[1]
           v= CGI::unescape(v)
           #puts "k / v: #{k} #{v}"
           if k.match(/^uri/)
              uris.push(v)
              if v.match(/^crid:/)
                crid = v
              end
              if v.match(/^dvb:/)
                dvb = v
              end
              if v.match(/^tag:feeds.bbc.co.uk/)
                pips = v
              end
              if v.match(/^http:\/\/www.bbc.co.uk\/programmes\//)
                prog = v
              end
           end
        end

        pp uris

#dvb://<original_network_id>.<transport_stream_id>.<service_id> is channel url
#3005.1044.1004.233a.dvb.tvdns.net

        channel_urls = {
"3098.1041.1041.233a.dvb.tvdns.net"=>"http://www.bbc.co.uk/services/bbcone#service",
"3098.10bf.1041.233a.dvb.tvdns.net"=>"http://www.bbc.co.uk/services/bbctwo#service",
"3098.10c0.1041.233a.dvb.tvdns.net"=>"http://www.bbc.co.uk/services/bbcthree#service",
"3098.1100.1041.233a.dvb.tvdns.net"=>"http://www.bbc.co.uk/services/bbcnews#service",
"3098.1140.1041.233a.dvb.tvdns.net"=>"http://www.bbc.co.uk/services/bbcredbutton#service",
"3098.11c0.1041.233a.dvb.tvdns.net"=>"http://www.bbc.co.uk/services/bbcfour#service",
"3098.1200.1041.233a.dvb.tvdns.net"=>"http://www.bbc.co.uk/services/cbbcchannel#service",
"3098.1280.1041.233a.dvb.tvdns.net"=>"http://www.bbc.co.uk/services/bbcparliament#service",
"3098.1600.1041.233a.dvb.tvdns.net"=>"http://www.bbc.co.uk/services/5live#service",
"3098.1640.1041.233a.dvb.tvdns.net"=>"http://www.bbc.co.uk/services/5livesportsextra#service",
"3098.1680.1041.233a.dvb.tvdns.net"=>"http://www.bbc.co.uk/services/6music#service",
"3098.16c0.1041.233a.dvb.tvdns.net"=>"http://www.bbc.co.uk/services/radio7#service",
"3098.1700.1041.233a.dvb.tvdns.net"=>"http://www.bbc.co.uk/services/1xtra#service",
"3098.1740.1041.233a.dvb.tvdns.net"=>"http://www.bbc.co.uk/services/asiannetwork#service",
"3098.1780.1041.233a.dvb.tvdns.net"=>"http://www.bbc.co.uk/services/worldservice#service",
"3098.1a40.1041.233a.dvb.tvdns.net"=>"http://www.bbc.co.uk/services/radio1#service",
"3098.1a80.1041.233a.dvb.tvdns.net"=>"http://www.bbc.co.uk/services/radio2#service",
"3098.1ac0.1041.233a.dvb.tvdns.net"=>"http://www.bbc.co.uk/services/radio3#service",
"3098.1b00.1041.233a.dvb.tvdns.net"=>"http://www.bbc.co.uk/services/radio4#service"
        }

        # look for the host
        # returns a MatchData object
        puts "HOST: #{req.host}"
        host = req.host
        host_chan = nil

        if host.match(/^([\da-f]{4})\.([\da-f]{4})\.([\da-f]{4})\.([\da-f]{4})(\.[^.]+)?\.(tvdns|radiodns)\.(org|net)$/i)
          if host.match("dvb://")
             host = host.gsub("dvb://","")
          end
          if channel_urls[host]
             host_chan = channel_urls[host]
             puts "found host #{host_chan}"
          else
             puts "no host match..."
          end
        end


# the logic is:
# if crid, just go ahead and look up that, resolve to progs
# if not crid
#  if dvb, look up that, resolve to progs
# if not dvb
#  if host and starttime, resolve to progs
#  if eventid and serviceid, resolve to progs
#  if pips or progs, return crid and dvb @@not done yet@@

        dont_redirect = false #hack to make pips / progs work
        begin
          # use the service to get the query
          serv = "http://dev.notu.be/2010/02/recommend/query"
          if crid
            uri = crid
            # remove any stray hash-numbers
            uri.gsub!(/#\d*$/,"")
            # make the sameas query
            q = "select ?p ?uri ?service ?start where {?uri <http://www.w3.org/2002/07/owl#sameAs> ?p . 
optional {
?broadcast <http://purl.org/ontology/po/broadcast_of> ?p .
?broadcast <http://purl.org/NET/c4dm/event.owl#time> ?time .
?time <http://purl.org/NET/c4dm/timeline.owl#start> ?start .
?broadcast <http://purl.org/ontology/po/broadcast_on> ?service .
} . FILTER regex(str(?uri), \"#{uri}\", \"i\")}"

            #puts q
          else
            if dvb
              uri = dvb
              # make the sameas query

              q = "select ?p ?uri ?service ?start where {
?uri <http://www.w3.org/2002/07/owl#sameAs> ?p .
?uri <http://www.w3.org/2002/07/owl#sameAs> ?dvb .
optional {
?broadcast <http://purl.org/ontology/po/broadcast_of> ?p .
?broadcast <http://purl.org/NET/c4dm/event.owl#time> ?time .
?time <http://purl.org/NET/c4dm/timeline.owl#start> ?start .
?broadcast <http://purl.org/ontology/po/broadcast_on> ?service .
} . FILTER regex(str(?dvb), \"#{dvb}\", \"i\")}"

            else
               if host_chan && utc

                  # regional variations
                  if(host_chan.match("bbcone") ||host_chan.match("bbctwo") || host_chan.match("radio4") ) 

                     q = "select ?p  ?start where {
?broadcast <http://purl.org/ontology/po/broadcast_of> ?p .
?broadcast <http://purl.org/NET/c4dm/event.owl#time> ?time .
?time <http://purl.org/NET/c4dm/timeline.owl#start> \"#{utc}\"^^<http://www.w3.org/2001/XMLSchema#dateTime> .
?broadcast <http://purl.org/ontology/po/broadcast_on> ?service .
?service <http://purl.org/ontology/po/parent_service> <#{host_chan}> .}"
                   else
                     q = "select ?p  ?start where {
?broadcast <http://purl.org/ontology/po/broadcast_of> ?p .
?broadcast <http://purl.org/NET/c4dm/event.owl#time> ?time .
?time <http://purl.org/NET/c4dm/timeline.owl#start> \"#{utc}\"^^<http://www.w3.org/2001/XMLSchema#dateTime> .
?broadcast <http://purl.org/ontology/po/broadcast_on> <#{host_chan}> .}"

                   end

               else
                 if eventid && serviceid
                    q = "select ?p ?uri ?service ?start where {
?uri <http://www.w3.org/2002/07/owl#sameAs> ?p . 
?uri <http://www.w3.org/2002/07/owl#sameAs> ?dvb . 
optional { ?broadcast 
<http://purl.org/ontology/po/broadcast_of> ?p . ?broadcast 
<http://purl.org/NET/c4dm/event.owl#time> ?time . ?time 
<http://purl.org/NET/c4dm/timeline.owl#start> ?start . ?broadcast 
<http://purl.org/ontology/po/broadcast_on> ?service .
} . FILTER regex(str(?dvb), \"#{serviceid}(.*)#{eventid}\", \"i\")}"
                 else
                   if pips || prog
                     dont_redirect = true
                     uri = "#{prog}#programme"
                     if pips
                       pid = pips.gsub("tag:feeds.bbc.co.uk,2008:PIPS:","")
                       uri = "http://www.bbc.co.uk/programmes/#{pid}#programme"
                     end
                     
                     q = "select ?crid ?dvb ?service ?start ?broadcast where {
?crid <http://www.w3.org/2002/07/owl#sameAs> <#{uri}> . 
?crid <http://www.w3.org/2002/07/owl#sameAs> ?dvb . 
optional {
?broadcast <http://purl.org/ontology/po/broadcast_of> <#{uri}> .
?broadcast <http://purl.org/NET/c4dm/event.owl#time> ?time .
?time <http://purl.org/NET/c4dm/timeline.owl#start> ?start .
?broadcast <http://purl.org/ontology/po/broadcast_on> ?service .
}}"

                   end
                 end
               end
            end
          end
          p = nil


          result = doQuery(serv,q)

          if result.length>1
             z = result[1] #we just take the first for now
             if(z && z.length>0)
               uu = z[0]
               p = uu["p"]

               res.status = 301
               if dont_redirect
                  res.body = JSON.pretty_generate(result)
               else
                 if (fmt && fmt=="rdf")
                   p = p.gsub("#programme",".rdf")
                   res.set_redirect(HTTPStatus::MovedPermanently, p)
                 else
                   p = uu["p"]
                   res.set_redirect(HTTPStatus::MovedPermanently, p)
                 end
               end
             else
               result=["404","No match found",warnings]
               res.body = JSON.pretty_generate(result)
             end
          else
             result=["404","No results found - service has failed",warnings]
             res.body = JSON.pretty_generate(result)
          end      
        rescue WEBrick::HTTPStatus::MovedPermanently=>e
          result=["301",{"uri"=>p},warnings]
          res.body = JSON.pretty_generate(result)
        rescue Exception=>e
          result=["404",e,warnings]
#         puts e.inspect
#         puts e.backtrace
          res.body = JSON.pretty_generate(result)
        end
        return res
      end

      def doQuery(serv,q)
        useragent = "NotubeMiniCrawler/0.1"
        z = serv + "?query=" + CGI.escape(q)
        u =  URI.parse z
        req = Net::HTTP::Get.new(u.request_uri,{'User-Agent' => useragent})
        req = Net::HTTP::Get.new( u.path+ '?' + u.query ) 
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
      end



