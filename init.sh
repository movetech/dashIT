#!/bin/bash

# Copyright (C) 2013 movetech Systemberatung <info@movetech.net>
# Copyright (C) 2013 Anton Kreuzkamp <akreuzkamp@web.de>
#
# This program is licensed under the terms of the GNU General Public License
# version 3 or above. See LICENSE.txt.

touch config.json

echo "This script will do the configuration and create a config file for you."
echo "Please insert the necessary information or just press Enter to use the default value specified in brackets."

read -p "Please insert the host on which the database lies [localhost]: " DBHOST
DBHOST=${DBHOST:-localhost}
read -p "Please insert the name of the database to use [dashIT]: " DBNAME
DBNAME=${DBNAME:-dashIT}
read -p "Please insert the username to use to access the database [dashIT]: " DBUSER
DBUSER=${DBUSER:-dashIT}
read -p "Please insert the password to use to access the database: " DBPASSWORD

read -p "Please insert the host name or IP adress of the mail server: " MAILHOST
read -p "Please insert the port to use on the mail server [143]: " MAILPORT
MAILPORT=${MAILPORT:-143}
read -p "Please insert the folder to use on the mail server [INBOX]: " MAILFOLDER
MAILFOLDER=${MAILFOLDER:-INBOX}
read -p "Please insert the username to use to authenticate with the mail server: " MAILUSER
read -p "Please insert the password to use to authenticate with the mail server: " MAILPASSWORD

echo "DashIT can send alarm messages via e-mail (e.g. to a ticket system) if a server sent an error message for the first time (repeating errors won't cause a new alarm)."
read -p "Please insert an e-mail address you want to receive alarm at. Leave empty for no alarm: " HELPDESKADDRESS
DEFAULTSENDERADDRESS="DashIT <dashIT@"`hostname`">"
read -p "Please insert the e-mail address to send alarm messages from [$DEFAULTSENDERADDRESS]: " HELPDESKSENDER
HELPDESKSENDER=${HELPDESKSENDER:-$DEFAULTSENDERADDRESS}

read -p "Please insert the number of months to store the messages in the database. \
Messages that are older than n month will be deleted from the database. Use -1 to never delete [6]: " HISTORYLENGTH
HISTORYLENGTH=${HISTORYLENGTH:-6}

read -p "The web interface can automatically refresh the view regularly. \
Please insert the interval in minutes. Use -1 to never refresh automatically [10]: " REFRESHINTERVAL
REFRESHINTERVAL=${REFRESHINTERVAL:-10}
read -p "For some use-cases it is helpful to increase the font size. \
Choose the font size in points (pt) to use [10]: " FONTPOINTSIZE
FONTPOINTSIZE=${FONTPOINTSIZE:-10}
read -p "For some use-cases it is helpful to change the font family. \
Choose the font family to use [sans-serif]: " FONTFAMILY
FONTFAMILY=${FONTFAMILY:-"sans-serif"}
read -p "For some use-cases it is helpful to change the indicator color for successful messages. \
Choose the color to use for successful messages [greenyellow]: " SUCCESSFULCOLOR
SUCCESSFULCOLOR=${SUCCESSFULCOLOR:-greenyellow}
read -p "For some use-cases it is helpful to change the indicator color for overdue messages. \
Choose the color to use for overdue messages [yellow]: " OVERDUECOLOR
OVERDUECOLOR=${OVERDUECOLOR:-yellow}
read -p "For some use-cases it is helpful to change the indicator color for bad messages. \
Choose the color to use for bad messages [red]: " BADCOLOR
BADCOLOR=${BADCOLOR:-red}

echo "{" > config.json
echo "    \"db\": {" >> config.json
echo "        \"host\": \"$DBHOST\"," >> config.json
echo "        \"name\": \"$DBNAME\"," >> config.json
echo "        \"user\": \"$DBUSER\"," >> config.json
echo "        \"password\": \"$DBPASSWORD\"" >> config.json
echo "    }," >> config.json
echo "    \"mailServer\": {" >> config.json
echo "        \"host\": \"$MAILHOST\"," >> config.json
echo "        \"port\": \"$MAILPORT\"," >> config.json
echo "        \"folder\": \"$MAILFOLDER\"," >> config.json
echo "        \"user\": \"$MAILUSER\"," >> config.json
echo "        \"password\": \"$MAILPASSWORD\"" >> config.json
echo "    }," >> config.json
echo "    \"helpdesk\": {" >> config.json
echo "        \"address\": \"$HELPDESKADDRESS\"," >> config.json
echo "        \"sender\": \"$HELPDESKSENDER\"" >> config.json
echo "    }," >> config.json
echo "    \"style\": {" >> config.json
echo "        \"fontPointSize\": \"$FONTPOINTSIZE\"," >> config.json
echo "        \"fontFamily\": \"$FONTFAMILY\"," >> config.json
echo "        \"successfulColor\": \"$SUCCESSFULCOLOR\"," >> config.json
echo "        \"overdueColor\": \"$OVERDUECOLOR\"," >> config.json
echo "        \"badColor\": \"$BADCOLOR\"" >> config.json
echo "    }," >> config.json
echo "    \"refreshInterval\": $REFRESHINTERVAL," >> config.json
echo "    \"historyLengthMonths\": $HISTORYLENGTH" >> config.json
echo "}" >> config.json

echo "Created config file."

mysql $DBNAME -h $DBHOST -u $DBUSER -p$DBPASSWORD < database.sql

echo "Created database tables."

echo "Finished initialization."
