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

    #p postdata
    url = 'https://direct18.shinseibank.co.jp/FLEXCUBEAt/LiveConnect.dll'
    res = @client.post(url, postdata)

    #puts res.body


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
        accounts[accountid[m[1].to_i]][:balance] = m[2]
    }

    res.body.scan(/fldCLACurrBalance\[(\d+)\]="([\w\.,]+)"/) { m = Regexp.last_match
        accounts[accountid[m[1].to_i]][:cla_balance] = m[2]
    }

    total = "0"
    if res.body =~/fldGrandTotalCR="([\d\.,]+)"/
      total = $1
    end

    @accounts = accounts
    @account_status = {:total=>total}
  end


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

  def get_history from,to
  end

  def getgrid account, cell
    x = cell[0].tr('A-J', '0-9').to_i
    y = cell[1].to_i

    account['GRID'][y][x]
  end

end

