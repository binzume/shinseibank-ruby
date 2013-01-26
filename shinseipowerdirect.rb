# -*- encoding: utf-8 -*-
#
#  新生銀行
#    http://www.binzume.net/
require "kconv"
require "rexml/document"
require "time"
require_relative "httpclient"

class ShinseiPowerDirect
  attr_accessor :account, :account_status, :accounts, :funds

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

    values= {}
    ['fldSessionID', 'fldGridChallange1', 'fldGridChallange2', 'fldGridChallange3', 'fldRegAuthFlag'].each{|k|
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

    accountid=[]
    accounts = {}
    res.body.scan(/fldAccountID\[(\d+)\]="(\w+)"/) { m = Regexp.last_match
        accountid[m[1].to_i] = m[2]
        accounts[m[2]] = {:id=>m[2]}
    }

    res.body.scan(/fldAccountType\[(\d+)\]="(\w+)"/) { m = Regexp.last_match
        accounts[accountid[m[1].to_i]][:type] = m[2]
    }

    res.body.scan(/fldAccountDesc\[(\d+)\]="([^"]+)"/) { m = Regexp.last_match
        accounts[accountid[m[1].to_i]][:desc] = m[2].toutf8
    }

    res.body.scan(/fldCurrCcy\[(\d+)\]="(\w+)"/) { m = Regexp.last_match
        accounts[accountid[m[1].to_i]][:curr] = m[2]
    }

    res.body.scan(/fldCurrBalance\[(\d+)\]="([\w\.,]+)"/) { m = Regexp.last_match
        accounts[accountid[m[1].to_i]][:balance] = m[2].gsub(/,/,'').to_f
    }

    res.body.scan(/fldBaseBalance\[(\d+)\]="([\w\.,]+)"/) { m = Regexp.last_match
        accounts[accountid[m[1].to_i]][:base_balance] = m[2].gsub(/,/,'').to_f
    }

    funds = []
    res.body.scan(/fldUHIDArray\[(\d+)\]="([\w\.,]+)"/) { m = Regexp.last_match
        funds[m[1].to_i] = { :id => m[2]}
    }
    res.body.scan(/fldFundNameArray\[(\d+)\]="([\w\.,]+)"/) { m = Regexp.last_match
        funds[m[1].to_i][:name] = m[2].toutf8
    }
    res.body.scan(/fldCurrentHoldingArray\[(\d+)\]="([\w\.,]+)"/) { m = Regexp.last_match
        funds[m[1].to_i][:holding] = m[2].gsub(/,/,'').to_i
    }
    res.body.scan(/fldValInBaseCurrArray\[(\d+)\]="([\w\.,]+)"/) { m = Regexp.last_match
        funds[m[1].to_i][:base_curr] = m[2].gsub(/,/,'').to_f
    }
    res.body.scan(/fldCurrentNAVArray\[(\d+)\]="([\w\.,]+)"/) { m = Regexp.last_match
        funds[m[1].to_i][:current_nav] = m[2].gsub(/,/,'').to_f
    }
    @funds = funds


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
  #   name = target 7digit account num.
  #   amount < 2000000 ?
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

    registered_account = []

    res.body.scan(/fldListPayeeAcctId\[(\d+)\]="([^"]+)"/).each{|m|
        registered_account[m[0].to_i] = {:account_id=>m[1]}
    }

    res.body.scan(/fldListPayeeAcctType\[(\d+)\]="([^"]+)"/) { m = Regexp.last_match
        registered_account[m[1].to_i][:account_type] = m[2]
    }

    res.body.scan(/fldListPayeeName\[(\d+)\]="([^"]+)"/) { m = Regexp.last_match
        registered_account[m[1].to_i][:name] = m[2]
    }

    res.body.scan(/fldListPayeeBank\[(\d+)\]="([^"]+)"/) { m = Regexp.last_match
        registered_account[m[1].to_i][:bank] = m[2]
    }

    res.body.scan(/fldListPayeeBankKanji\[(\d+)\]="([^"]+)"/) { m = Regexp.last_match
        registered_account[m[1].to_i][:bank_kanji] = m[2]
    }

    res.body.scan(/fldListPayeeBankKana\[(\d+)\]="([^"]+)"/) { m = Regexp.last_match
        registered_account[m[1].to_i][:bank_kana] = m[2]
    }

    res.body.scan(/fldListPayeeBranch\[(\d+)\]="([^"]+)"/) { m = Regexp.last_match
        registered_account[m[1].to_i][:branch] = m[2]
    }

    res.body.scan(/fldListPayeeBranchKanji\[(\d+)\]="([^"]+)"/) { m = Regexp.last_match
        registered_account[m[1].to_i][:branch_kanji] = m[2]
    }

    res.body.scan(/fldListPayeeBranchKana\[(\d+)\]="([^"]+)"/) { m = Regexp.last_match
        registered_account[m[1].to_i][:branch_kana] = m[2]
    }

    #p registered_account

    values= {}
    ['fldRemitterName', 'fldInvoice', 'fldInvoicePosition','fldDomFTLimit', 'fldRemReimburse'].each{|k|
      if res.body =~/#{k}=['"]([^'"]*)['"]/
        values[k] = $1
      end
    }

    target_account = registered_account.find{|a| a[:account_id] == name  };
    from_name = values['fldRemitterName']
    account = @accounts.keys[0] # とりあえず普通円預金っぽいやつ

    postdata = {
      'MfcISAPICommand'=>'EntryFunc',
      'fldAppID'=>'RT',
      'fldTxnID'=>'ZNT',
      'fldScrSeqNo'=>'07',
      'fldRequestorID'=>'74',
      'fldSessionID'=> @ssid,

      'fldAcctId' => account,
      'fldAcctType' => @accounts[account][:type] ,
      'fldAcctDesc'=> @accounts[account][:desc],
      'fldMemo'=> from_name,
      #'fldRemitterName'=> '',
      #'fldInvoice'=>'',
      #'fldInvoicePosition'=>'B',
      'fldTransferAmount' => amount,
      'fldTransferType'=>'P', # P(registerd) or D
      #'fldPayeeId'=>'',
      'fldPayeeName' => target_account[:name],
      'fldPayeeAcctId' => target_account[:account_id],
      'fldPayeeAcctType' => target_account[:account_type],
      #fldPayeeBankCode:undefined
      'fldPayeeBankName' => target_account[:bank],
      'fldPayeeBankNameKana' => target_account[:bank_kana],
      'fldPayeeBankNameKanji' => target_account[:bank_kanji],
      #fldPayeeBranchCode:undefined
      'fldPayeeBranchName' => target_account[:branch],
      'fldPayeeBranchNameKana' => target_account[:branch_kana],
      'fldPayeeBranchNameKanji' => target_account[:branch_kanji],
      #fldSearchBankName:
      #fldSearchBranchName:
      #fldFlagRegister:
      #'fldDomFTLimit'=>'4000000',
      #'fldRemReimburse'=>4,
    }.merge(values)


    res = @client.post(url, postdata)

    values= {}
    ['fldMemo', 'fldInvoicePosition', 'fldTransferType', 'fldTransferDate', 'fldTransferFeeUnformatted',
      'fldDebitAmountUnformatted', 'fldReimbursedAmt', 'fldRemReimburse'].each{|k|
      if res.body =~/#{k}=['"]([^'"]*)['"]/
        values[k] = $1
      end
    }

    postdata = {
      'MfcISAPICommand'=>'EntryFunc',
      'fldAppID'=>'RT',
      'fldTxnID'=>'ZNT',
      'fldScrSeqNo'=>'08',
      'fldRequestorID'=>'76',
      'fldSessionID'=> @ssid,

      'fldAcctId' => @accounts.keys[0],
      'fldAcctType' => @accounts[ @accounts.keys[0] ][:type] ,
      'fldAcctDesc'=> @accounts[ @accounts.keys[0] ][:desc],
      #'fldMemo'=> from_name,
      'fldRemitterName'=> target_account[:name],
      #'fldInvoice'=>'',
      #'fldInvoicePosition'=>'B',
      'fldTransferAmount' => amount,
      'fldTransferType'=>'P', # P(registerd) or D
      #'fldTransferDate' => transfar_date,
      #'fldPayeeId'=>'',
      'fldPayeeName' => target_account[:name],
      'fldPayeeAcctId' => target_account[:account_id],
      'fldPayeeAcctType' => target_account[:account_type],
      #fldPayeeBankCode:undefined
      'fldPayeeBankName' => target_account[:bank],
      'fldPayeeBankNameKana' => target_account[:bank_kana],
      'fldPayeeBankNameKanji' => target_account[:bank_kanji],
      #fldPayeeBranchCode:undefined
      'fldPayeeBranchName' => target_account[:branch],
      'fldPayeeBranchNameKana' => target_account[:branch_kana],
      'fldPayeeBranchNameKanji' => target_account[:branch_kanji],
      #fldSearchBankName:
      #fldSearchBranchName:
      #fldFlagRegister:
      #'fldDomFTLimit'=>'4000000',
    }.merge(values)

    p postdata
    res = @client.post(url, postdata)
    puts res.body

  end

  private
  def getgrid account, cell
    x = cell[0].tr('A-J', '0-9').to_i
    y = cell[1].to_i

    account['GRID'][y][x]
  end

end

