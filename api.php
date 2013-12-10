<?php
/*
 * Copyright (C) 2013 movetech Systemberatung <info@movetech.net>
 * Copyright (C) 2013 Anton Kreuzkamp <akreuzkamp@web.de>
 *
 * This program is licensed under the terms of the GNU General Public License
 * version 3 or above. See LICENSE.txt.
 */

require 'ext-lib/Slim/Slim.php';
\Slim\Slim::registerAutoloader();
$app = new \Slim\Slim(array(
    'log.level' => \Slim\Log::DEBUG
));
$return = new stdClass();

// === Get Configuration ===
$confStr = file_get_contents(__DIR__ . "/config.json");
if ($confStr === false) {
    $return->error = "No config found or config is empty. Have you run install.sh?";
    die(json_encode($return));
}

$config = json_decode($confStr);
if ($config === false) {
    $return->error = "Config is no valid JSON. Please check the syntax.";
    die(json_encode($return));
}

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
    $return->error = "No database connection could be established: " . $e->getMessage();
    die(json_encode($return));
}

// === GET /servers ===
$app->get('/servers', function () {
    global $pdo;
    $stm = $pdo->prepare("select * from `servers`");
    $stm->execute();
    $serverList = $stm->fetchAll(PDO::FETCH_ASSOC);
    $stm->closeCursor();

    $stm = $pdo->prepare("select `lastUpdate` from `information` limit 1");
    $stm->execute();
    $return->lastUpdate = $stm->fetch(PDO::FETCH_COLUMN, 0);
    $stm->closeCursor();

    foreach ($serverList as $i => $server) {
        $stm = $pdo->prepare("select `received`,`bad` from `messages`
                                where `serverId`=:serverId
                                order by `received` desc
                                limit 8");
        $stm->execute(array(':serverId' => $server['serverId']));
        $messages = $stm->fetchAll(PDO::FETCH_ASSOC);
        $stm->closeCursor();

        if ($messages)
            $serverList[$i]['history'] = $messages;
        else
            $serverList[$i]['history'] = array(array("received" => "", "bad" => 0));


        $stm = $pdo->prepare("select `rule` from `rules`
                                where `serverId`=:serverId");
        $stm->execute(array(':serverId' => $server['serverId']));
        $rules = $stm->fetchAll(PDO::FETCH_COLUMN, 0);
        $stm->closeCursor();

        if ($rules)
            $serverList[$i]['rules'] = $rules;
        else
            $serverList[$i]['rules'] = array();


        $stm = $pdo->prepare("select * from `pauses`
                                where `serverId`=:serverId");
        $stm->execute(array(':serverId' => $server['serverId']));
        $pauses = $stm->fetchAll(PDO::FETCH_ASSOC);
        $stm->closeCursor();

        if ($pauses)
            $serverList[$i]['pauses'] = $pauses;
        else
            $serverList[$i]['pauses'] = array();
    }

    $return->serverList = $serverList;
    print json_encode($return);
});

// === GET /servers/id ===
$app->get('/servers/:id', function ($id) {
    global $pdo;
    $stm = $pdo->prepare(
        "select `messageId`,`received`,`bad` from `messages`
            where `serverId`=:serverId and datediff(now(), `received`) < 31");
    $stm->execute(array(':serverId' => $id));
    $messageList = $stm->fetchAll(PDO::FETCH_ASSOC);
    $stm->closeCursor();

    print json_encode($messageList);
});

// === GET /servers/id/year/month ===
$app->get('/servers/:id/:year/:month', function ($id, $year, $month) {
    global $pdo;
    $stm = $pdo->prepare(
        "select `messageId`,`received`,`bad` from `messages`
            where `serverId`=:serverId and datediff(`received`, :selectedDate) between 0 and 30");
    $stm->execute(array(':serverId' => $id,
                        ':selectedDate' => "$year-$month-01"));
    $messageList = $stm->fetchAll(PDO::FETCH_ASSOC);
    $stm->closeCursor();

    print json_encode($messageList);
});

// === GET /servers/id/year/month/day ===
$app->get('/servers/:id/:year/:month/:day', function ($id, $year, $month, $day) {
    global $pdo;
    $stm = $pdo->prepare(
        "select `messageId`,`received`,`subject`,`message`,`bad` from `messages`
            where `serverId`=:serverId and datediff(:selectedDate, `received`) = 0");
    $stm->execute(array(':serverId' => $id,
                        ':selectedDate' => "$year-$month-$day"));
    $messageList = $stm->fetchAll(PDO::FETCH_ASSOC);
    $stm->closeCursor();

    print json_encode($messageList);
});

// === GET /messages/id ===
$app->get('/messages/:id', function ($id) {
    global $pdo;
    $stm = $pdo->prepare(
        "select * from `messages`
            where messageId=:messageId");
    $stm->execute(array(':messageId' => $id));
    $messageList = $stm->fetchAll(PDO::FETCH_ASSOC);
    $stm->closeCursor();

    print json_encode($messageList[0]);
});
 
// === POST /servers ===
$app->post('/servers', function () {
    global $pdo;

    $pdo->beginTransaction();
    $stm = $pdo->prepare(
        "insert into `servers` (`name`, `sender`, `interval`)
            values (:name, :sender, :interval)");
    $stm->execute(array(':name' => $_POST['name'],
                        ':sender' => $_POST['sender'],
                        ':interval' => $_POST['interval']));
    $id = $pdo->lastInsertId();

    if (isset($_POST['rules'])) {
        foreach ($_POST['rules'] as $rule) {
            $stm = $pdo->prepare(
                "insert into `rules` (`serverId`, `rule`)
                    values (:serverId, :rule)");
            $stm->execute(array(':serverId' => $id,
                                ':rule' => $rule));
        }
    }
    if (isset($_POST['pauses'])) {
        foreach ($_POST['pauses'] as $pause) {
            $stm = $pdo->prepare(
                "insert into `pauses` (`serverId`, `beginWeekday`, `beginHour`, `endWeekday`, `endHour`)
                    values (:serverId, :beginWeekday, :beginHour, :endWeekday, :endHour)");
            $stm->execute(array(':serverId' => $id,
                                ':beginWeekday' => $pause['beginWeekday'],
                                ':beginHour' => $pause['beginHour'],
                                ':endWeekday' => $pause['endWeekday'],
                                ':endHour' => $pause['endHour']));
        }
    }
    $pdo->commit();
});
 
// === PUT /servers/id ===
$app->put('/servers/:id', function ($id) {
    global $pdo,$app;

    $data = json_decode($app->request->getBody());
    error_log($id);

    $pdo->beginTransaction();
    $stm = $pdo->prepare(
        "update `servers`
            set `name`=:name, `sender`=:sender, `interval`=:interval
            where `serverId`=:serverId");
    $stm->execute(array(':name' => $data->name,
                        ':sender' => $data->sender,
                        ':interval' => $data->interval,
                        ':serverId' => $id));

    $stm = $pdo->prepare("delete from `rules` where `serverId`=:serverId");
    $stm->execute(array(':serverId' => $id));
    $stm = $pdo->prepare("delete from `pauses` where `serverId`=:serverId");
    $stm->execute(array(':serverId' => $id));

    foreach ($data->rules as $rule) {
        $stm = $pdo->prepare(
            "insert into `rules` (`serverId`, `rule`)
                values (:serverId, :rule)");
        $stm->execute(array(':serverId' => $id,
                            ':rule' => $rule));
    }

    foreach ($data->pauses as $pause) {
        $stm = $pdo->prepare(
            "insert into `pauses` (`serverId`, `beginWeekday`, `beginHour`, `endWeekday`, `endHour`)
                values (:serverId, :beginWeekday, :beginHour, :endWeekday, :endHour)");
        $stm->execute(array(':serverId' => $id,
                            ':beginWeekday' => isset($pause->beginWeekday) ? $pause->beginWeekday : -1,
                            ':beginHour' => $pause->beginHour,
                            ':endWeekday' => isset($pause->endWeekday) ? $pause->endWeekday : -1,
                            ':endHour' => $pause->endHour));
    }
    $pdo->commit();
});
 
// === DELETE /servers/id ===
$app->delete('/servers/:id', function ($id) {
    global $pdo;
    $stm = $pdo->prepare("delete from `servers` where `serverId`=:serverId");
    $stm->execute(array(':serverId' => $id));
    $stm->closeCursor();
});
 
$app->run();
?>