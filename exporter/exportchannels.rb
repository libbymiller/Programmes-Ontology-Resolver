require 'rubygems'
require 'json/pure'
require 'net/http'
require 'uri'
gem 'dbi'
require "dbi"
gem 'dbd-mysql'
require 'pp'

#export of the data we ened from the mythtv atabase
#basicaly we want 
#components separated by tab: crid, dvb, start, end, channel, title
#crid may not be abvailable
#dvb is made up of data from channelscan_channel:
#<netid>.<service_id>.<sdt_tsid>.<orig_netid>.dvb.tvdns.net

def enc(netid,service_id,sdt_tsid,orig_netid)
  n = netid.to_s(16)
  si = service_id.to_s(16)
  st = sdt_tsid.to_s(16)
  on = orig_netid.to_s(16)
  ch = "#{n}.#{si}.#{st}.#{on}.dvb.tvdns.net"
#  ch = "dvb://#{n}.#{si}.#{st}.#{on}.dvb.tvdns.net"
#  ch1 = "dvb://#{netid}.#{service_id}.#{sdt_tsid}.#{orig_netid}.dvb.tvdns.net"
#  ch = "dvb://#{orig_netid}.#{sdt_tsid}.#{service_id}"
#  puts "----"
#  puts ch1
#  puts ch
  return ch
end

# do the main body
def generateAndProcess()
  txtresults = ""

  # create the query
  d = DateTime.now
  dt = d.strftime("%Y-%m-%d")
  q = "select distinct 
netid,service_id,sdt_tsid,orig_netid,channel.callsign 
from channelscan_channel,channel where 
channelscan_channel.chan_num = channel.channum "
#and channel.callsign like '%bbc%'"
#and channel.callsign like '%beeb%'"
#limit 1"
#  q = "select  netid,service_id,sdt_tsid,orig_netid,programid,starttime,endtime, channel.callsign,title  from channelscan_channel,channel, program where  channelscan_channel.chan_num = channel.channum and channel.chanid =  program.chanid and starttime >= '2010-06-20' and  starttime < '2010-06-21' and channel.callsign = 'BBC ONE'";

  puts q

  results = query(q)

  #loop through, tidying up the crid and generating the dvb uri

  results.each do |r|
     dvb = enc(r[0].to_i,r[1].to_i,r[2].to_i,r[3].to_i)     
     ch = r[4].to_s.gsub(" ","").downcase

#return the results tab separated, one line for each
     txtresults = "#{txtresults}
#{dvb}|#{r[4].to_s}"
#\"#{dvb}\"=>\"http://www.bbc.co.uk/#{ch}#service\""
  end
  return txtresults
end


def connect_to_mysql()
        puts "\nConnecting to MySQL..."
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
  
  return arr
end



begin
   data =  generateAndProcess()
   puts data

end
