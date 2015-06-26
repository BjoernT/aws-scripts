#!/usr/bin/env python
import os
import smtplib
import time
import random
import socket


def base36encode(number):
    if not isinstance(number, (int, long)):
        raise TypeError('number must be an integer')
    if number < 0:
        raise ValueError('number must be positive')

    alphabet = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ'

    base36 = ''
    while number:
        number, i = divmod(number, 36)
        base36 = alphabet[i] + base36

    return base36 or alphabet[0]

def base36decode(number):
    return int(number,36)

mailfrom='bjoern@xxx'
mailto='bjoern@xxxx'
maildir='./mailz' #Where are my sample mails stored
smtpserver='127.0.0.1'

for dirname, dirnames, filenames in os.walk(maildir):
   for filename in filenames:
      file = os.path.join(dirname, filename)
      try:
         fh = open(file,'r')
         ignoreuntilfrom = 1
         mail = []
         localtime = time.localtime(time.time())
         hostname = socket.gethostname()
         server = smtplib.SMTP(smtpserver)
         server.set_debuglevel(1)

         try:
            for line in fh:
               ll = line.lower()
               if ll.startswith('from:'):
                  ignoreuntilfrom = 0

               if ignoreuntilfrom == 0:
                  if ll.startswith(('x-','dkim-signature:','domainkey-signature:')):
                     continue
                  if ll.startswith('from:'):
                     line = 'From: '+ mailfrom + '\r\n'
                  if ll.startswith('to:'):
                     line = 'To:' + mailto + '\r\n'
                  if ll.startswith('date:'):
                     line = 'Date: ' + time.strftime("%a, %d %b %Y %H:%M:%S -0700",localtime) + '\r\n'
                  if ll.startswith('message-id:'):
                     random.seed()
                     msgid = base36encode( int(time.time()) +  int(random.getrandbits(64)) )
                     line = 'Message-ID: <' + msgid +'@'+ hostname +'>\r\n'
                  mail.append(line)
         finally:
            server.sendmail('From: ' + mailfrom, 'To: ' + mailto, ''.join(mail))
            server.quit()
            fh.close()
      except IOError as ex:
         print "Could not open file {0}: {1}" .format(file, ex.strerror)
