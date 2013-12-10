<?php
/*
 * Copyright (C) 2013 movetech Systemberatung <info@movetech.net>
 * Copyright (C) 2013 Anton Kreuzkamp <akreuzkamp@web.de>
 *
 * This program is licensed under the terms of the GNU General Public License
 * version 3 or above. See LICENSE.txt.
 */
?>
<!DOCTYPE html>
<html>
    <head>
        <title>dashIT</title>
        <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
        <link rel="stylesheet" href="ext-lib/jquery-ui/css/ui-lightness/jquery-ui-1.10.3.custom.css">
        <link rel="stylesheet" href="style/stylesheet.css">
        <script type="text/javascript" src="ext-lib/jquery-ui/js/jquery-1.9.1.js"></script>
        <script type="text/javascript" src="ext-lib/jquery-ui/js/jquery-ui-1.10.3.custom.min.js"></script>
        <script type="text/javascript" src="ext-lib/qmlweb/src/parser.js"></script>
        <script type="text/javascript" src="ext-lib/qmlweb/src/import.js"></script>
        <script type="text/javascript" src="ext-lib/qmlweb/src/qtcore.js"></script>
    </head>
    <body style="margin: 0;">
        <script type="text/javascript">
            <?php
                $confStr = file_get_contents(__DIR__ . "/config.json");
                if ($confStr !== false) {
                    $config = json_decode($confStr);
                    if ($config !== false) {
                        print "var fontPointSize = " . json_encode($config->style->fontPointSize) . ";\n";
                        print "var fontFamily = " . json_encode($config->style->fontFamily) . ";\n";
                        print "var successfulColor = " . json_encode($config->style->successfulColor) . ";\n";
                        print "var overdueColor = " . json_encode($config->style->overdueColor) . ";\n";
                        print "var badColor = " . json_encode($config->style->badColor) . ";\n";
                        print "var refreshInterval = " . json_encode($config->refreshInterval) . ";\n";
                    } else {
                        print "alert('Die Konfigurationsdatei enthält kein valides JSON. Bitte prüfen Sie die Syntax.');";
                    }
                } else {
                    print "alert('Es wurde keine Konfigurationsdatei gefunden. Haben Sie install.sh ausgeführt?');";
                }
            ?>

            var qmlEngine = new QMLEngine();
            qmlEngine.loadFile("qml/main.qml");
            qmlEngine.start();
        </script>
    </body>
</html>