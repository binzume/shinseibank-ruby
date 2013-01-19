#!/usr/bin/ruby -Ku
# -*- encoding: utf-8 -*-

require 'yaml'
require_relative 'shinseipowerdirect'

shinsei_account = YAML.load_file('shinsei_account.yaml')
powerdirect = ShinseiPowerDirect.new

# login
unless powerdirect.login(shinsei_account)
  puts 'LOGIN ERROR'
  exit
end

begin
  puts 'total: ' + powerdirect.total_balance.to_s
  powerdirect.recent.each do |row|
    p row
  end

  p powerdirect.accounts
ensure
  # logout
  powerdirect.logout
end

puts "ok"

