#!/usr/bin/ruby -Ku

require 'test/unit'
require 'yaml'
require_relative 'shinseipowerdirect'

class ShinseiPowerDirectTest < Test::Unit::TestCase
  def setup
    @account = YAML.load_file('shinsei_account.yaml')
    @m = ShinseiPowerDirect.new
  end

  def test_login

    unless @m.login(@account)
      puts "LOGIN ERROR"
    end

    begin
      assert(@m.account_status != nil)
      assert(@m.accounts.length > 0)
      p @m.account_status[:total]
      p @m.accounts
      p @m.recent
    ensure
      # logout
      @m.logout
    end
  end

end


