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



登録済み口座に振り込む

 powerdirect.transfer_to_registered_account('registed_account_num', 50000)
 # TODO:将来的にconfirmメソッドで確定するようにする

投資信託を買う(すでに買ってあるやつを追加で)

  fund = powerdirect.funds[0]
  req = powerdirect.buy_fund fund, 1000000
  powerdirect.confitm req

投資信託を解約

  fund = powerdirect.funds[0]
  req = powerdirect.sell_fund fund, 1230000
  powerdirect.confitm req


あらゆる動作は無保証です．実装と動作をよく確認して使ってください．

