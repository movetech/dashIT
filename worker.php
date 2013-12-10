<?php
/*
 * Copyright (C) 2013 movetech Systemberatung <info@movetech.net>
 * Copyright (C) 2013 Anton Kreuzkamp <akreuzkamp@web.de>
 *
 * This program is licensed under the terms of the GNU General Public License
 * version 3 or above. See LICENSE.txt.
 */

ob_implicit_flush(1);

// === Configuration ===
$confStr = file_get_contents(__DIR__ . "/config.json");
if ($confStr === false)
    die("No config found or config is empty. Have you run install.sh?\n");

$config = json_decode($confStr);
if ($config === false)
    die("Config is no valid JSON. Please check the syntax.\n");

// === Database connection ===
global $pdo;
try {
    $pdoConnectionString = 'mysql:host=' . $config->db->host
                            . ';dbname=' . $config->db->name;
    $pdo = new PDO($pdoConnectionString, $config->db->user, $config->db->password,
                    array(PDO::ATTR_PERSISTENT => true,
                            PDO::ATTR_ERRMODE => PDO::ERRMODE_WARNING,
                            PDO::MYSQL_ATTR_USE_BUFFERED_QUERY => true,
                            PDO::MYSQL_ATTR_INIT_COMMAND => 'set names utf8'));
} catch (PDOException $e) {
    die("No database connection could be established: " . $e->getMessage() . "\nAborting.\n");
}


// === IMAP Connection ===
echo "Connecting to IMAP server...";
$mailbox = imap_open("{{$config->mailServer->host}:{$config->mailServer->port}/novalidate-cert}/{$config->mailServer->folder}", $config->mailServer->user, $config->mailServer->password);
if ($mailbox === false)
    die("No IMAP connection could be established. Aborting.\n");
echo "Connected.\n";

// Get the datetime of the last run of this script.
$stm = $pdo->prepare("select lastUpdate from information limit 1");
$stm->execute();
$lastUpdate = substr($stm->fetch(PDO::FETCH_COLUMN, 0), 0, 10);
$stm->closeCursor();

// === Get list of servers. ===
$stm = $pdo->prepare("select * from `servers`");
$stm->execute();
$serverList = $stm->fetchAll(PDO::FETCH_ASSOC);
$stm->closeCursor();

$servers = array();

foreach ($serverList as $i => &$server) {
    $stm = $pdo->prepare("select received,bad from `messages`
                            where serverId=:serverId
                            order by received desc
                            limit 8");
    $stm->execute(array(':serverId' => $server['serverId']));
    $messages = $stm->fetchAll(PDO::FETCH_ASSOC);
    $stm->closeCursor();

    if ($messages)
        $server['history'] = $messages;
    else
        $server['history'] = array(array("received" => "", "bad" => 0));

    $servers[$server['sender']] = $server;
}

// Search for mails since last run of this script (with a daily accuracy)
echo "Fetching mails since $lastUpdate...";
$mailIds = imap_search($mailbox, "SINCE $lastUpdate");
$mailCount = count($mailIds);
echo "Fetched $mailCount Mails.\n";

// === Import Mail ===
foreach($mailIds as $mNo => $mId) {
    // Get mail
    $header = imap_headerinfo($mailbox, $mId);
    if ($header->Deleted == 'D')
        continue;

    // Build sender address
    $mailaddress = "{$header->from[0]->mailbox}@{$header->from[0]->host}";

    if (isset($servers[$mailaddress])) { // sender is a known server
        echo "Importing mail $mNo/$mailCount \"{$header->subject}\" from $mailaddress...";

        $server = $servers[$mailaddress];
        $serverId = $server['serverId'];
        $mail = imap_body($mailbox, $mId);

        // Check whether the mail is good or bad.
        echo "Checking if mail is bad...";
        $stm = $pdo->prepare("select rule from `rules`
                                where serverId=:serverId");
        $stm->execute(array(':serverId' => $serverId));
        $rules = $stm->fetchAll(PDO::FETCH_COLUMN, 0);
        $stm->closeCursor();

        $bad = false;
        foreach ($rules as $rule) {
            if ($rule[0] == '/') {
                if (preg_match($rule, $mail) === 1)
                    $bad = true;
            } else {
                if (strpos($mail, $rule) !== false)
                    $bad = true;
            }
        }

        // Create ticket to helpdesk
        if ($bad && $config->helpdesk->address) {
            if ($server['history'][0]['bad'] == "1") {
                echo "\nMessage is an error message, but the last one was bad as well. Guess we have already opened a ticket.\n";
            } else {
                echo "\nMessage is an error message, opening Ticket.\n";
                // Send a mail to the ticket system (We don't send one, if the
                // last message was an error message as well, because in this
                // case we have already sent one)
                imap_mail($config->helpdesk->address,
                    "Error message for {$server['name']} received.",
                    "DashIT received a error message for server \"{$server['name']}\" on {$header->date}.\n\n"
                    . "The message was:\n\n"
                    . $header->subject . "\n\n"
                    . substr($mail, 0, 1000),
                    "From: {$config->helpdesk->sender}");
            }
        }

        // insert  message into database (replacing duplicate entries using
        // UNIQUE indices (there is a UNIQUE index for mailId)).
        $stm = $pdo->prepare("replace messages (serverId, received, mailId, subject, message, bad)
                                values(:serverId, from_unixtime(:received), :mailId, :subject, :message, :bad)");
        $stm->execute(array(':serverId' => $serverId,
                            ':received' => $header->udate,
                            ':mailId' => $header->message_id,
                            ':subject' => $header->subject,
                            ':message' => $mail,
                            ':bad' => $bad));
        $stm->closeCursor();
        echo "Done. Classified as " . ($bad ? "bad" : "successful") . ".\n";
    } else { // Sender is unknown
        echo "Ignoring mail $mNo/$mailCount \"{$header->subject}\" from $mailaddress: Address not in server list.\n";
    }
}

imap_close($mailbox);

// === Delete old mails ===
if ($config->historyLengthMonths !== -1) {
    echo "Deleting messages older than {$config->historyLengthMonths} months from database...";
    $stm = $pdo->prepare("delete from messages where received < date_sub(now(), interval {$config->historyLengthMonths} month)");
    $stm->execute();
    $stm->closeCursor();
    echo "Done\n";
}

// === Update lastUpdate ===
$stm = $pdo->prepare("update information set lastUpdate = now()");
$stm->execute();
$stm->closeCursor();

echo "Finished.\n";


?>