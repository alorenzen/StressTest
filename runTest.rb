#!/usr/bin/env ruby
require 'xmlrpc/client'

#usage:
# ./runTest.rb <master_ip> <master_port> <web_server_ip> <webserver_port> <file> <prefix_for_test> <number_of_requests>
# prefix_for_test is just used for logging on the master
# number_of_requests is number for each slave

master = ARGV[0]
master_port = ARGV[1]
server = ARGV[2]
server_port = ARGV[3]
file = ARGV[4]
prefix = ARGV[5]
numrequests = ARGV[6]

client = XMLRPC::Client.new2("http://#{master}:#{master_port}")
client.call("run_test",prefix,server,server_port,file,numrequests)
