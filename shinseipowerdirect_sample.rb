#!/usr/bin/ruby -Ku
# -*- encoding: utf-8 -*-
#

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

  # 登録済み口座に振り込み 200万円まで？？
  # powerdirect.transfer_to_registered_account('登録済み振込先の口座番号7桁(仮)', 50000)

ensure
  # logout
  powerdirect.logout
end

puts "ok"

