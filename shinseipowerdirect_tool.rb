#!/usr/bin/ruby -Ku
# -*- encoding: utf-8 -*-
#
#  新生銀行コマンドラインツール
#  Shinsei power direct commandline tools
#
# @author binzume  http://www.binzume.net/
#

require 'yaml'
require_relative 'shinseipowerdirect'

shinsei_account = YAML.load_file('shinsei_account.yaml')
powerdirect = ShinseiPowerDirect.new

if ARGV.length < 1
  puts "usage:  "
  puts "  account show"
  puts "  account history [account_id]"
  puts "  fund list"
  puts "  fund all"
  puts "  fund sell fund_id units ['confirm']"
  puts "  fund buy fund_id yen ['confirm']"
  exit
end


# login
unless powerdirect.login(shinsei_account)
  puts 'LOGIN ERROR'
  exit
end

begin


  case ARGV[0]
  when 'account'
    puts 'total: ' + powerdirect.total_balance.to_s
    powerdirect.accounts.values.find_all{|a|a[:balance]>0}.each{|a|
      p a
    }
    powerdirect.recent.each do |row|
      p row
    end
  when 'fund'

    case ARGV[1]
    when 'list'
      powerdirect.funds.each{|f|
        p f
      }
    when 'all'
      powerdirect.all_funds.each{|f|
        p f
      }
    when 'buy'
      # todo: support all_funds
      fund = powerdirect.funds.find{|f| f[:id] == ARGV[2]}
      unless fund
        puts "invalid fund_id"
        exit
      end
      req = powerdirect.buy_fund fund, ARGV[3]
      p req
      if ARGV[4] == 'confirm'
        puts 'submit!'
        powerdirect.confirm req
        fname = Time.now.strftime('%Y%m%d_%H%M%S') + "_buy_fund.html"
        open(fname,'w'){|f| f.write(powerdirect.last_html) }
      end
    when 'sell'
      fund = powerdirect.funds.find{|f| f[:id] == ARGV[2]}
      unless fund
        puts "invalid fund_id"
        exit
      end
      req = powerdirect.sell_fund fund, ARGV[3]
      p req
      if ARGV[4] == 'confirm'
        puts 'submit!'
        powerdirect.confirm req
        fname = Time.now.strftime('%Y%m%d_%H%M%S') + "_sell_fund.html"
        open(fname,'w'){|f| f.write(powerdirect.last_html) }
      end

    else
      puts 'unknown mode'
    end

  else
    puts 'unknown command'
  end

ensure
  # logout
  powerdirect.logout
end

puts "ok"

