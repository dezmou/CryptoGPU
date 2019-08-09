import traceback
import smtplib
from email.mime.text import MIMEText
import time
import datetime

def sendMail(subject, content):
    try:
        
        message = """From: Modez Error Reporting <from@fromdomain.com>
To: To Person <to@todomain.com>
MIME-Version: 1.0
Content-type: text/html
Subject: """ + subject + """

An Error occured : <br/>            
<strong><pre>""" + content + """</pre></strong>
<br/>
<br/>
at : """ + str( datetime.datetime.now().strftime("%d-%m-%Y %H:%M") ) + """

"""
        server = smtplib.SMTP('smtp.gmail.com', 587)
        server.starttls()
        server.login("", "")

        server.sendmail("error@dez.com", "", message)
        server.quit()
    except:
        ex = traceback.format_exc()
        with open ('/var/www/html/cryptolog.txt', 'a') as f:
            f.write("\n\n MAIL REPORTING FAILURE : " + str(datetime.datetime.now().strftime("%d-%m-%Y %H:%M")) + '\n' + ex + "\n\n")
