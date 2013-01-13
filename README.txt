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


# mizuhodirect_sample.rb
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
  p m.recent
ensure
  # logout
  m.logout
end

puts "ok"


