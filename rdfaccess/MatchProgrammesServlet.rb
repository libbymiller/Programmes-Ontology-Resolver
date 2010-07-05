   require 'date'
   require 'webrick'
   require 'webrick/accesslog'
   include WEBrick
   require 'uri'
   require 'cgi'
   require 'open-uri'
   require 'net/http'
   require 'rubygems'
   require 'json/pure'
   require 'java'
   require 'date'
   require 'pp'
   require 'insertdata.rb'

   class MatchProgrammesServlet < HTTPServlet::AbstractServlet

 # if it's a get we look for a query
      def do_POST(req, res)
        res['Content-Type'] = 'text/javascript'
        res.status = 404
        data = req.query["data"]
        puts data
# we expect crid://foobar1  dvb://foobar1   2010-06-14T19:00:00     
#2010-06-14T19:35:00     bbc2    Something Else
#tab separated
# we process it using insertdata.rb which also adds it to the databaase
        result = ["404","No data"]
        if (data && data!="")

          begin
            r = go(data)
            result=["200",r]
          rescue Exception=>e
            result=["404",e]
            puts e.inspect
            puts e.backtrace
          end
        end
        res.body = JSON.pretty_generate(result)
      end

      # cf. http://www.hiveminds.co.uk/node/244, published under the
      # GNU Free Documentation License, http://www.gnu.org/copyleft/fdl.html

      @@instance = nil
      @@instance_creation_mutex = Mutex.new

      def self.get_instance(config, *options)
         #pp @@instance
         @@instance_creation_mutex.synchronize {
            @@instance = @@instance || self.new(config, *options) }
      end
                        

   end
