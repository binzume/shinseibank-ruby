This is a Shinsei-bank PowerDirect (Shinsei-bank internet banking) library for Ruby.
- http://www.shinseibank.com/

作りかけ．残高は取れます．

Require:


Exapmple:

# shinsei_account.yaml
ID: "4009999999"
PASS: "********"
NUM: "1234"
GRID:
 - ZXCVBNMBNM
 - ASDFGHJKLL
 - QWERTYUIOP
 - 1234567890
 - ZXCVBNMBNM

口座番号，パスワード，暗証番号とセキュリティーカードの情報を書いてください．


# shinseipowerdirect_sample.rb
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



