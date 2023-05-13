#!/usr/bin/php -f

<?php
/*
File name: SendSMS_Justin.php
Author: Justin Tai
Date created: 2023/05/10
Date last modified: 2023/05/12
Version : 1.0

###############################################################
Version 1.0 : Send SMS to every8d

*/

class SMSHttp{
	var $smsHost;
	var $sendSMSUrl;
	var $getCreditUrl;
	var $batchID;
	var $credit;
	var $processMsg;
	
    public function __construct(){
        $this->SMSHttp();
    }

	function SMSHttp(){
		$this->smsHost = "biz3.e8d.tw/company_name";
		$this->sendSMSUrl = "https://".$this->smsHost."/API21/HTTP/sendSMS.ashx";
		$this->batchID = "";
		$this->credit = 0.0;
		$this->processMsg = "";
	}
	
	/// <summary>
	/// 傳送簡訊
	/// </summary>
	/// <param name="userID">帳號</param>
	/// <param name="password">密碼</param>
	/// <param name="subject">簡訊主旨，主旨不會隨著簡訊內容發送出去。用以註記本次發送之用途。可傳入空字串。</param>
	/// <param name="content">簡訊發送內容(不需要進行urlencode)</param>
	/// <param name="mobile">接收人之手機號碼。格式為: +886912345678或09123456789。多筆接收人時，請以半形逗點隔開( , )，如0912345678,0922333444。</param>
	/// <param name="sendTime">簡訊預定發送時間。-立即發送：請傳入空字串。-預約發送：請傳入預計發送時間，若傳送時間小於系統接單時間，將不予傳送。格式為YYYYMMDDhhmnss；例如:預約2009/01/31 15:30:00發送，則傳入20090131153000。若傳遞時間已逾現在之時間，將立即發送。</param>
	/// <returns>true:傳送成功；false:傳送失敗</returns>
	function sendSMS($userID, $password, $subject, $content, $mobile, $sendTime){
		$success = false;
		$postArr["UID"] 	= $userID;
		$postArr["PWD"]		= $password;
		$postArr["SB"]		= $subject;
		$postArr["MSG"]		= $content;
		$postArr["DEST"]	= $mobile;
		$postArr["ST"]		= $sendTime;
		$sms_time = date("F j, Y, g:i a");
		$smslog_dir = "/var/log/";
		$sms_file = $smslog_dir."HMS_SMS_Status.log";
		global $contact;

		$resultString = $this->httpPost($this->sendSMSUrl, $postArr);
		if((substr($resultString,0,1) == "-") || (strlen($resultString)<=1) ){
			$this->processMsg = $resultString;
			$smslog = strtolower(str_repeat("#",50)."\nSMS Send Failure at ".$sms_time." - ".$content."\n".$contact."\n".$mobile."\n".$resultString."\n");
			$sms_status = false;
		} else {
			$success = true;
			$strArray = explode(",", $resultString);
			$this->credit = $strArray[0];
			$this->batchID = $strArray[4];
			$smslog = strtolower(str_repeat("#",50)."\nSMS Send Successfull at ".$sms_time." - ".$content."\n".$contact."\n".$mobile."\n".$resultString."\n");
			$sms_status = true;
		}

		# write sms send log
		$fh_sms = fopen($sms_file, 'a+');
		fwrite($fh_sms, $smslog);
		fclose($fh_sms);

		return $success;
	}
	
	//若php版本過低未含  curl 功能,請安裝 curl 套件或升級 php
	function httpPost($url, $postArray){
		$curl = curl_init();
		curl_setopt($curl, CURLOPT_URL, $url);
		curl_setopt($curl, CURLOPT_HEADER, 1);
	    curl_setopt($curl, CURLOPT_FOLLOWLOCATION, true );
		curl_setopt($curl, CURLOPT_RETURNTRANSFER, 1);
		curl_setopt($curl, CURLOPT_POST, true);
		curl_setopt($curl, CURLOPT_SSLVERSION, 6);  //Force requsts to use TLS 1.2
		curl_setopt($curl, CURLOPT_POSTFIELDS, http_build_query($postArray));
		$res = curl_exec($curl);
		if($res === false)
		{
    		return "-1000: ".curl_error($curl);
		}
		$http_status = curl_getinfo($curl, CURLINFO_HTTP_CODE);
		curl_close($curl);
		if($http_status!=200) return "-2000: http status code: ".$http_status;
		$strArray = explode("\r\n\r\n", $res);
		$idx=count($strArray)-1;
		if(!isset($strArray[$idx])) return "-".$errno.":$errstr \nRESPONSE:\"".$res."\"";

    	return $strArray[$idx];
	}
}



$NOTIFICATIONTYPE = $argv[1];
$HOSTALIAS = $argv[2];
$HOSTNAME = $argv[3];
$HOSTADDRESS = $argv[4];
$SERVICEDESC = $argv[5];
$SERVICESTATE = $argv[6];
$LONGDATETIME = $argv[7];
$SERVICEOUTPUT = $argv[8];
$CONTACTMOBILE = $argv[9];
$CONTACTNAME = $argv[10];

$userID = "*****";  //..EVERY8D.. 
$password = "*****"; //..EVERY8D..
$subject = "$SERVICESTATE - $HOSTALIAS: $SERVICEOUTPUT;";
$content = "NODE:$HOSTNAME\n$SERVICEDESC is $SERVICESTATE\n$LONGDATETIME";
$mobile = $CONTACTMOBILE;
$contact = $CONTACTNAME;
$sendTime = "";

if (isset($argv[9])) {
	$SERVICEDESC = trim($SERVICEDESC);
	$SMSHttp = new SMSHttp;
        $SMSHttp->sendSMS($userID,$password,$subject,$content,$mobile,$sendTime);
	} else {
		exit;
	}


?>
