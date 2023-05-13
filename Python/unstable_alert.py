#!/usr/bin/env python3
############################################################################
#    File name: unstable_alert.py                                          #
#    Author: Justin Tai                                                    #
#    Date created: 2022/01/21                                              #
#    Date last modified: 2022/01/24                                        #
#    Python Version: 3.8.5                                                 #
#    Version: 1.1                                                          #
############################################################################
#    Version 1.0 : Auto Parse Nagios unstable alert
#    Version 1.1 : Fix total alert string conversion to int type.
############################################################################

from datetime import date
from selenium import webdriver
from selenium.webdriver.common.action_chains import ActionChains
from selenium.webdriver.support.ui import Select
from selenium.webdriver.common.by import By
from selenium.webdriver.chrome.service import Service
import time
import openpyxl
from bs4 import BeautifulSoup


#設定環境變數
PATH = "D:\chromedriver.exe"
unstable_url = "http://aaa.com.tw/nagiosxi/reports/topalertproducers.php?reportperiod=last24hours&startdate=&enddate=&starttime=1642661681&endtime=1642748081&search=&host=&service=&hostgroup=&servicegroup=&statetype=hard&hostservice=both&state=&export=0&page=1&mode=getpage&records=500"
driver = webdriver.Chrome(PATH)
driver.get("http://aaa.com.tw/nagiosxi/login.php")
actions = ActionChains(driver)
unstable_data = []
wb = openpyxl.Workbook()
sheet = wb.create_sheet("不穩定告警",0)
i = 0

#登入Nagios
account = driver.find_element_by_id("usernameBox")
account.send_keys("Nagios")
pw = driver.find_element_by_id("passwordBox")
nagios_password = input("Please Input Nagios Password  \n")
pw.send_keys(nagios_password)
login = driver.find_element_by_id("loginButton").click()
time.sleep(2)

#轉到不穩定告警頁面
driver.get(unstable_url)
time.sleep(2)

#抓取不穩定告警頁面的第一列的數字
Total_alerts = (int(driver.find_element_by_xpath('/html/body/table/tbody/tr[1]/td[1]/a').text))

#比對第一列的數字若沒有大於等於24的話，就不動作，若有的話，則開始將事件寫入到excel。
if Total_alerts >= 24 :
    soup = BeautifulSoup(driver.page_source,"html.parser")
    tables = soup.find("tbody")
    
    while True:
        trs = tables.find_all("tr")[i]
        i = i+1
        for tr in trs:
            unstable_data.append(tr.getText())
        if int(unstable_data[0]) >= 24: #確認要寫入到excel中抓取到的事件數是否有大於等於24，若沒有則結束程式，若有的話則寫入excel。
            unstable_data[0] = int(unstable_data[0]) #將total alert從字串轉換成整數。2022/01/24 by Justin
            sheet.append (unstable_data)
            del unstable_data[0:4]
            wb.save("unstable.xlsx")
        else:
            break
          
    
else:
    wb.save("unstable.xlsx")