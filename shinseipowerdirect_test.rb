#!/usr/bin/ruby -Ku
require 'yaml'
require_relative "shinseipowerdirect"

account = YAML.load_file('shinsei_account.yaml')

# login
m = ShinseiPowerDirect.new
unless m.login(account)
  puts "LOGIN ERROR"
end

begin
  p m.account_status[:total]
  p m.accounts
ensure
  # logout
  m.logout
end

puts "ok"


