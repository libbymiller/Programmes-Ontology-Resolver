require 'rubygems'
require 'json/pure'
require 'net/http'
require 'uri'
gem 'dbi'
require "dbi"
gem 'dbd-mysql'
require 'pp'

#export of the data we need from the mythtv atabase
#basicaly we want 
#components separated by tab: crid, dvburl, start, end, channel, title
#crid may not be available
# in this version, svb url is genearted by myth itself
# see Baird mythtv patches to produce these: http://projectbaird.com/patches/mythtv/


# do the main body
def generateAndProcess()
  allresults = ""

  # create the query
  d = DateTime.now
  dt = d.strftime("%Y-%m-%d")
  d2 = d+1
  puts d2
  dt2 = d2.strftime("%Y-%m-%d")

# these are currently the only ones available
  chans = ["BBC ONE","BBC TWO", "BBC THREE", "BBC FOUR","CBBC Channel","CBeebies","BBC Parliament","BBC NEWS","BBC Red Button",
"BBC R5L","BBC R5SX","BBC 6 Music","BBC Radio 7", "BBC R1X","BBC Asian Net.",
"BBC World Sv.","BBC Radio 1","BBC Radio 2","BBC Radio 3","BBC Radio 4"]
#  chans=["BBC THREE","BBC FOUR"]

# we don't have data in the crawler db from after today (i.e. for progs)

  chans.each do |ch|

    txtresults = ""

    q = "select 
programid,starttime,endtime, channel.callsign,title,programuri from channelscan_channel,channel, program where 
channelscan_channel.chan_num = channel.channum and channel.chanid = 
program.chanid and starttime >= \"#{dt}\" and starttime <= \"#{dt2}\" 
and channel.callsign = '#{ch}' "

    puts "query is #{q}"

    results = query(q)
    puts "found #{results.length} results"
    #loop through, tidying up the crid and generating the dvb uri

    results.each do |r|

      crid = r[0]
      if(crid!=nil && crid!="")
         crid = "crid://#{crid}"
      else
         crid = nil
      end

      ds = r[1]
      de = r[2]
      dvb = r[5]


      # myth stores the times without timezone so we need to make sure 
      # we have the correct timezone in the correct format, otherwise it 
      # defaults as 0 offset we get the timezone from the local time

      t = Time.new
      z = t.zone

      # then parse the start and end dates into times using the timezone 
      # we found

      ss = ds.strftime("%Y-%m-%d %H:%M:%S")
      sss = "#{ss.to_s} #{z}"
      ts = Time.parse(sss)
      st = ts.xmlschema()

      ee = de.strftime("%Y-%m-%d %H:%M:%S")
      eee = "#{ee.to_s} #{z}"
      te = Time.parse(eee)
      et = te.xmlschema()

      # this is the channel. we just keep it as the callsign
      # various apps will munge it to fit

      ch = r[3]
      title = r[4]

      #return the results tab separated, one line for each
      puts "adding line #{crid}|#{dvb}|#{st}|#{et}|#{ch}|#{title}"
      txtresults = "#{txtresults}
#{crid}|#{dvb}|#{st}|#{et}|#{ch}|#{title}"
    end

# post it to the server
# we do it channel by channel or it times out
    serv = "http://dev.notu.be/2010/02/recommend/match"
    puts "posting data"
    puts post_data(serv,txtresults)
    allresults = "#{allresults}#{txtresults}"
    sleep 5

  end
  return allresults
end


def connect_to_mysql()
        puts "\nConnecting to MySQL..."
        # hardcoded!
        return DBI.connect('DBI:Mysql:mythconverg', 'mythtv', '196NYOxZ')
end


# query the sql database
def query(q)
   begin
      dbh = connect_to_mysql()
      query = dbh.prepare(q)
      query.execute()               
      arr = []
      while row = query.fetch() do
         arr.push(row.to_a)
      end
      dbh.commit
      query.finish
      dbh.disconnect
   end

#  example data  
#  row = ["12440","8268","8204","9018","www.itv.com/22862523","2010-06-14 01:20:00","2010-06-14 02:30:00","ITV1","The Zone"]
#  row1 = ["12440","4161","4161","9018","fp.bbc.co.uk/5a6s28","2010-06-14 00:05:00","2010-06-14 00:10:00","BBC ONE","Weatherview"]
#  arr.push(row)
#  arr.push(row1)
  return arr
end


def post_data(serv,data)
  
              useragent = "NotubeMiniCrawler/0.1"
              u =  URI.parse serv
              req = Net::HTTP::Post.new(u.request_uri,{'User-Agent' => useragent})

              if(data)
                req.set_form_data({'data'=>data}, ';')
              else
                puts "no data to post"
                return 
              end
              req.basic_auth 'notube', 'ebuton'

              begin

                res2 = Net::HTTP.new(u.host, u.port).start {|http|
                  http.read_timeout = 1000
                  http.request(req) 
                }
              rescue Timeout::Error=>e
                puts "Timeout error - #{e}"
              rescue Errno::ECONNRESET=>f
                puts "Connection Reset - #{f}"
              rescue Errno::ETIMEDOUT=>g
                puts "Connection Timeout - #{g}"
              end

              r = nil
              if(res2)
                r = res2.body
              else
                r = nil
              end
              return r
end

begin
   results = generateAndProcess()
   puts "[1]"
#save them for testcases later
   d = DateTime.now
   puts "[2]"
   dt = d.strftime("%Y-%m-%d")
   puts "[3]"
   local_filename = "data/matchdata-#{dt}.txt"
   puts "[4]"
   File.open(local_filename, 'w') {|f| f.write(results) }
   puts "[5]"

end
