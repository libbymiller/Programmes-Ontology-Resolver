   require 'date'
   require 'webrick'
   require 'webrick/accesslog'
   include WEBrick
   require 'uri'
   require 'open-uri'
   require 'net/http'
   require 'rubygems'
   require 'json/pure'
   require 'java'
   require 'date'
   require 'pp'

   Dir.glob("TDB-0.8.4/lib/*.jar") { |jar| require jar }

   java_import "com.hp.hpl.jena.tdb.TDB"
   java_import "com.hp.hpl.jena.tdb.TDBFactory"
   java_import "com.hp.hpl.jena.util.FileManager"
   java_import "com.hp.hpl.jena.query.QueryExecutionFactory"
   java_import "com.hp.hpl.jena.query.ResultSetFormatter"

   class QueryServlet < HTTPServlet::AbstractServlet

 # if it's a get we look for a query
      def do_GET(req, res)
        res['Content-Type'] = 'text/javascript'
        res.status = 200
        query = req.query["query"]

        TDB.getContext.set(TDB.symUnionDefaultGraph, true)
        dataset = TDBFactory.create_dataset("DataStore")

        base = "http://www.bbc.co.uk/"
        begin 
           if query && query!=""
              query = query.to_s #doesn't like ruby strings
              qe = QueryExecutionFactory.create(query, dataset)
              results = qe.exec_select
              result_arr=[]
              results.each do |r|
                 row_hash={}                 
                 r.varNames().each do |z|
                    p = r.get(z).to_s
#                   puts "#{z} #{p}"
                    row_hash[z]=p
                 end
                 result_arr.push(row_hash)
              end
              result=["200",result_arr]
          else
              result=["404"]
          end
        rescue Exception=>e
          result=["300",e]
        end
        res.body = JSON.pretty_generate(result)
      end

# if it's a post we look for a url to post in
      def do_POST(req, res)
        res['Content-Type'] = 'text/javascript'
        res.status = 200
        url = req.query["url"]
        url = url.to_s #jena doesn't like ruby strings
        if url && url!=""
           begin

              TDB.getContext.set(TDB.symUnionDefaultGraph, true)
              dataset = TDBFactory.create_dataset("DataStore")
              base = "http://www.bbc.co.uk/"
              nm = dataset.get_named_model(url)
              nm.remove_all
              puts "**** trying to read url #{url}"
              FileManager.get.read_model(nm, url, base, "RDF/XML")  
# if there's a q parameter, return results of the q

              u = url.gsub(".rdf","#programme")

              q = req.query["q"]
              result_arr=[]
              if (q)
                query = q.to_s
#               query = "select ?v where {<#{u}> <http://purl.org/ontology/po/version> ?v}"

                qe = QueryExecutionFactory.create(query, dataset)
                results = qe.exec_select
                results.each do |r|
                   row_hash={}                 
                   r.varNames().each do |z|
                      p = r.get(z).to_s
                      puts "#{z} #{p}"
                      row_hash[z]=p
                   end
                   result_arr.push(row_hash)
                end
              end
              result=["200",result_arr]
           rescue Exception => e
              result=["300",e]
           end
        else
           result=["404",url]
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
