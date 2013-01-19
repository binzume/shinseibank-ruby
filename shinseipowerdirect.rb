# -*- encoding: utf-8 -*-
#
#  新生銀行
#    http://www.binzume.net/
require "kconv"
require "rexml/document"
require "time"
require_relative "httpclient"

class ShinseiPowerDirect
  attr_accessor :account, :account_status, :accounts

  def initialize(account = nil)
    @account_status = {:total=>nil}

    if account
      login(account)
    end
  end

  ##
  # ログイン
  def login(account)
    @account = account
    ua = "Mozilla/5.0 (Windows; U; Windows NT 5.1;) PowerDirectBot/0.1"
    @client = HTTPClient.new(:agent_name => ua)

    postdata = {
      'MfcISAPICommand'=>'EntryFunc',
      'fldAppID'=>'RT',
      'fldTxnID'=>'LGN',
      'fldScrSeqNo'=>'01',
      'fldRequestorID'=>'41',
      'fldDeviceID'=>'01',
      'fldLangID'=>'JPN',
      'fldUserID'=>account['ID'],
      'fldUserNumId'=>account['NUM'],
      'fldUserPass'=>account['PASS'],
      'fldRegAuthFlag'=>'A'
    }

    url = 'https://direct18.shinseibank.co.jp/FLEXCUBEAt/LiveConnect.dll'
    res = @client.post(url, postdata)

    keys = ['fldSessionID', 'fldGridChallange1', 'fldGridChallange2', 'fldGridChallange3', 'fldRegAuthFlag']
    values= {}

    keys.each{|k|
      if res.body =~/#{k}=['"](\w+)['"]/
        values[k] = $1
      end
    }

    @ssid = values['fldSessionID']

    postdata = {
      'MfcISAPICommand'=>'EntryFunc',
      'fldAppID'=>'RT',
      'fldTxnID'=>'LGN',
      'fldScrSeqNo'=>'41',
      'fldRequestorID'=>'55',
      'fldSessionID'=> @ssid,
      'fldDeviceID'=>'01',
      'fldLangID'=>'JPN',
      'fldGridChallange1'=>getgrid(account, values['fldGridChallange1']),
      'fldGridChallange2'=>getgrid(account, values['fldGridChallange2']),
      'fldGridChallange3'=>getgrid(account, values['fldGridChallange3']),
      'fldUserID'=>'',
      'fldUserNumId'=>'',
      'fldNumSeq'=>'1',
      'fldRegAuthFlag'=>values['fldRegAuthFlag'],
    }

    url = 'https://direct18.shinseibank.co.jp/FLEXCUBEAt/LiveConnect.dll'
    res = @client.post(url, postdata)

    get_accounts
  end

  ##
  # ログアウト
  def logout
    postdata = {
      'MfcISAPICommand'=>'EntryFunc',
      'fldAppID'=>'RT',
      'fldTxnID'=>'CDC',
      'fldScrSeqNo'=>'49',
      'fldRequestorID'=>'',
      'fldSessionID'=> @ssid,

      'fldIncludeBal'=>'Y',
      'fldCurDef'=>'JPY'
    }

    #p postdata
    url = 'https://direct18.shinseibank.co.jp/FLEXCUBEAt/LiveConnect.dll'
    res = @client.post(url, postdata)

  end

  ##
  # 残高確認
  def total_balance
    @account_status[:total]
  end

  ##
  # 直近の取引履歴
  def recent
    get_history nil, nil, @accounts.keys[0]
  end

  def get_accounts

    postdata = {
      'MfcISAPICommand'=>'EntryFunc',
      'fldAppID'=>'RT',
      'fldTxnID'=>'ACS',
      'fldScrSeqNo'=>'00',
      'fldRequestorID'=>'23',
      'fldSessionID'=> @ssid,

      'fldAcctID'=>'', # 400????
      'fldAcctType'=>'CHECKING',
      'fldIncludeBal'=>'Y',
      'fldPeriod'=>'',
      'fldCurDef'=>'JPY'
    }

    #p postdata
    url = 'https://direct18.shinseibank.co.jp/FLEXCUBEAt/LiveConnect.dll'
    res = @client.post(url, postdata)

    #puts res.body

    accountid=[]
    accounts = {}
    res.body.scan(/fldAccountID\[(\d+)\]="(\w+)"/) { m = Regexp.last_match
        accountid[m[1].to_i] = m[2]
        accounts[m[2]] = {:id=>m[2]}
    }

    res.body.scan(/fldCurrCcy\[(\d+)\]="(\w+)"/) { m = Regexp.last_match
        accounts[accountid[m[1].to_i]][:curr] = m[2]
    }

    res.body.scan(/fldCurrBalance\[(\d+)\]="([\w\.,]+)"/) { m = Regexp.last_match
        accounts[accountid[m[1].to_i]][:balance] = m[2].gsub(/,/,'').to_f
    }

    res.body.scan(/fldCLACurrBalance\[(\d+)\]="([\w\.,]+)"/) { m = Regexp.last_match
        accounts[accountid[m[1].to_i]][:cla_balance] = m[2].gsub(/,/,'').to_f
    }

    total = "0"
    if res.body =~/fldGrandTotalCR="([\d\.,]+)"/
      total = $1.gsub(/,/,'').to_i
    end

    @accounts = accounts
    @account_status = {:total=>total}

  end

  def get_history from,to,id

    postdata = {
      'MfcISAPICommand'=>'EntryFunc',
      'fldAppID'=>'RT',
      'fldTxnID'=>'ACA',
      'fldScrSeqNo'=>'01',
      'fldRequestorID'=>'9',
      'fldSessionID'=> @ssid,

      'fldAcctID'=> id, # 400????
      'fldAcctType'=>'CHECKING',
      'fldIncludeBal'=>'N',

      'fldStartDate'=> from ? from.strftime('%Y%m%d') : '',
      'fldEndDate'=> to ? to.strftime('%Y%m%d') : '',
      'fldStartNum'=>'0',
      'fldEndNum'=>'0',
      'fldCurDef'=>'JPY',
      'fldPeriod'=>'1'
    }

    #p postdata
    url = 'https://direct18.shinseibank.co.jp/FLEXCUBEAt/LiveConnect.dll'
    res = @client.post(url, postdata)

    history = []

    res.body.scan(/fldDate\[(\d+)\]="([^"]+)"/) { m = Regexp.last_match
        history[m[1].to_i] = {:date=>m[2]}
    }

    res.body.scan(/fldDesc\[(\d+)\]="([^"]+)"/) { m = Regexp.last_match
        history[m[1].to_i][:description] = m[2].toutf8
    }

    res.body.scan(/fldRefNo\[(\d+)\]="([^"]+)"/) { m = Regexp.last_match
        history[m[1].to_i][:ref_no] = m[2]
    }

    res.body.scan(/fldDRCRFlag\[(\d+)\]="([^"]+)"/) { m = Regexp.last_match
        history[m[1].to_i][:drcr] = m[2]
    }

    res.body.scan(/fldAmount\[(\d+)\]="([^"]+)"/) { m = Regexp.last_match
        history[m[1].to_i][:amount] = m[2].gsub(/[,\.]/,'').to_i
        if history[m[1].to_i][:drcr] == 'D'
          history[m[1].to_i][:out] = m[2].gsub(/[,\.]/,'').to_i
        else
          history[m[1].to_i][:in] = m[2].gsub(/[,\.]/,'').to_i
        end
    }

    res.body.scan(/fldRunningBalanceRaw\[(\d+)\]="([^"]+)"/) { m = Regexp.last_match
        history[m[1].to_i][:balance] = m[2].gsub(/,/,'').to_i
    }

    @account_status = {:total=>history[0][:amount], :id=>id}
    history[1..-1]
  end

  ##
  # move to registered account
  # NOT IMPLEMENTED
  def transfer_to_registered_account name, amount

    postdata = {
      'MfcISAPICommand'=>'EntryFunc',
      'fldAppID'=>'RT',
      'fldTxnID'=>'ZNT',
      'fldScrSeqNo'=>'00',
      'fldRequestorID'=>'71',
      'fldSessionID'=> @ssid,
    }

    #p postdata
    url = 'https://direct18.shinseibank.co.jp/FLEXCUBEAt/LiveConnect.dll'
    res = @client.post(url, postdata)
    puts res.body

    registered_account = []

    res.body.scan(/fldListPayeeAcctId\[(\d+)\]="([^"]+)"/) { m = Regexp.last_match
        registered_account[m[1].to_i] = {:account_id=>m[2]}
    }

    res.body.scan(/fldListPayeeAcctType\[(\d+)\]="([^"]+)"/) { m = Regexp.last_match
        registered_account[m[1].to_i][:account_type] = m[2]
    }

    res.body.scan(/fldListPayeeName\[(\d+)\]="([^"]+)"/) { m = Regexp.last_match
        registered_account[m[1].to_i] = {:name=>m[2]}
    }

    res.body.scan(/fldListPayeeBank\[(\d+)\]="([^"]+)"/) { m = Regexp.last_match
        registered_account[m[1].to_i][:bank] = m[2].toutf8
    }

    res.body.scan(/fldListPayeeBranch\[(\d+)\]="([^"]+)"/) { m = Regexp.last_match
        registered_account[m[1].to_i][:branch] = m[2]
    }

    p registered_account
  end

  private
  def getgrid account, cell
    x = cell[0].tr('A-J', '0-9').to_i
    y = cell[1].to_i

    account['GRID'][y][x]
  end

end

