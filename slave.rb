#!/usr/bin/env ruby

#usage:
#./stressTest <master_ip> <master_port> <slave_port>
# run this on every slave, will stay alive 
# until the master stops responding

require 'xmlrpc/server'
require 'xmlrpc/client'
require 'repeat'
require 'open-uri'

MASTER_HOST = ARGV[0]
MASTER_PORT = ARGV[1]
SLAVE_PORT = ARGV[2]

def runStressTest(prefix,host,port,file,numrequests)
  times = Array.new
  request = "http://#{host}:#{port}/#{file}"
  puts request
  failed = 0
  1.upto(numrequests.to_i) do |i|
    puts i
    begin
      start = Time.now
      open(request, "Host:"=>"abc") {|f| f.read}
      stop = Time.now
      times << (stop - start)
    rescue
      failed += 1
    end
  end  
  master = XMLRPC::Client.new2("http://#{MASTER_HOST}:#{MASTER_PORT}")
  master.call("collect_results",prefix,host,port,IP,times,failed)
end

if `/sbin/ifconfig` =~ /(137\.165\.[\d]+\.[\d]+)/
  IP = $~[0]
  Thread.new() do
    Repeat::Every 2.minutes do
      begin
        master = XMLRPC::Client.new2("http://#{MASTER_HOST}:#{MASTER_PORT}")
        master.timeout=(2*20*60)
        master.call("heart_beat",IP,SLAVE_PORT)
      rescue => ex
        puts "Master not responding"
        Process.kill("HUP",$$)
      end
    end
  end
  s = XMLRPC::Server.new(SLAVE_PORT,IP)
  s.add_handler("stress_test") do |prefix,host,port,file,numrequests|
    fork do
      runStressTest(prefix,host,port,file,numrequests)
    end
    0
  end
  s.serve
end
