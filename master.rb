#!/usr/bin/env ruby

#use:
# ./master.rb <port>

require 'xmlrpc/server'
require 'xmlrpc/client'
require 'repeat'
require 'concurrent_hash'

SLAVES = ConcurrentHash.new
RESULTS = ConcurrentHash.new
master_port = ARGV[0]

def heart_beat(ip,port)
  STDERR.puts "HeartBeat: #{ip}:#{port}"
  SLAVES[ip] = {:port => port, :time => Time.now}
end

def run_test(prefix,host,port,file,numrequests)
  results = Hash.new
  results[:times] = Hash.new
  results[:failed] = 0
  puts "Starting test for #{prefix}-#{host}:#{port}"
  STDOUT.flush
  SLAVES.each do |ip,hash|
    results[:times][ip] = nil
    slave = XMLRPC::Client.new2("http://#{ip}:#{hash[:port]}")
    slave.call("stress_test",prefix,host,port,file,numrequests)
  end
  RESULTS[prefix] = results
end

def collect_results(prefix,host,port,slave_ip,times,failed) 
  results = RESULTS[prefix]
  results[:times][slave_ip] = times
  results[:failed] += failed.to_i
  average = times.inject{|sum,el| sum+el}.to_f / times.size
  puts "Average time for #{prefix} from #{slave_ip}: #{average} - #{failed} failed"
  STDOUT.flush
  unless results[:times].has_value?(nil) then
    times = results[:times].values.flatten
    average = times.inject{|sum,el| sum+el}.to_f / times.size
    puts "Average time for #{prefix}: #{average} - #{results[:failed]} failed"
    STDOUT.flush
    RESULTS[prefix] = nil
  end
end

def check_slaves()
  SLAVES.reject! do |ip,hash|
    delay = Time.now - hash[:time]
    if delay > 5.minutes then
      STDERR.puts "Slave #{ip}:#{hash[:port]} is not responding"
      true
    else
      false
    end
  end
end

thread = Thread.new() do 
  Repeat::Every 5.minutes do
    check_slaves
  end
end
if `/sbin/ifconfig` =~ /(137\.165\.[\d]+\.[\d]+)/
  ip = $~[0]
  s = XMLRPC::Server.new(master_port,ip)
  s.add_handler("heart_beat") do |ip,port| 
    heart_beat(ip,port)
    0
  end
  s.add_handler("run_test") do |prefix,ip,port,file,numrequests| 
    run_test(prefix,ip,port,file,numrequests) 
    0
  end
  s.add_handler("collect_results") do |prefix,host,port,slave_ip,times,failed|
    collect_results(prefix,host,port,slave_ip,times,failed)
    0
  end
  s.serve
end
