<?php
/**
 * Created by cryptek.
 * Date: 30/09/2020
 * Time: 10:07
 */

$countArgv = count($argv);
if($countArgv < 2){
    echo "usage:\nphp generate_indicator.php NNFX_News_offline.mq4\n\t--nnfx-events=1\n\t--high-impact=0\n";
    exit(0);
}

$options = [];
$i = 2;
while($i < $countArgv){
    if(substr($argv[$i], 0, 2) == '--' && ($pos = strpos($argv[$i], '=')) !== false){
        $options[substr($argv[$i], 2, $pos - 2)] = substr($argv[$i], $pos + 1);
    }
    $i++;
}

$newsPath = "news";
if(!is_dir($newsPath)){
    echo "error: folder {$newsPath} not found\n";
    return;
}

$filterEvents = [
    'USD' => [
        'Non-Farm Employment',
        'FOMC Statement',
        'Fed Chairman',
        'CPI m/m'
    ],
    'EUR' => [
        'ECB Press Conference',
        'ECB President',
    ],
    'GBP' => [
        'MPC Official Bank',
        'Prelim GDP'
    ],
    'CAD' => [
        'BOC Rate Statement',
        'Unemployment Rate',
        'Non-Farm Employment',
        'Core Retail Sales',
        'CPI m/m',
    ],
    'AUD' => [
        'Cash Rate',
        'Unemployment Rate',
        'Employment Change',
    ],
    'CHF' => [
        'SNB Monetary Policy Assessment',
        'Libor Rate',
    ],
    'JPY' => [
        'Monetary Policy Statement',
    ],
    'NZD' => [
        'Unemployment Rate',
        'Employment Change',
        'GDP',
        'GDT Price Index',
        'Official Cash Rate',
    ],
];


if (!($handle = opendir($newsPath))) {
    echo "error: opendir {$newsPath}\n";
    return;
}

$files = [];
while (false !== ($file = readdir($handle))) {
    if ($file === "." || $file === "..") {
        continue;
    }
    if(preg_match('/(\d{4})_(\d{2})\.html/', $file, $m)){
        $files[$file] = [$m[1], $m[2]];
    }
}
closedir($handle);

if(empty($files)){
    echo "error: {$newsPath} is empty\n";
    return;
}
ksort($files);

$events = [];
foreach($files as $file => $fDate) {
    list($year, $month) = $fDate;
    $html = file_get_contents($newsPath . '/' . $file);

    preg_match_all('/<tr class="calendar__row calendar_row[^>]*>(.*?)<\/tr>/s', $html, $m, PREG_SET_ORDER);
    $len = count($m);

    $dateDay = 1;
    $eventDay = '';
    for ($i = 0; $i < $len; $i++) {
        $trHtml = $m[$i][0];

        $dom = new \DOMDocument();
        $dom->loadHTML($trHtml, LIBXML_HTML_NODEFDTD | LIBXML_HTML_NOIMPLIED);

        $tr = $dom->firstChild;
        $currency = '';
        $event = '';
        $impact = '';
        $actual = '';
        $forecast = '';
        $previous = '';
        foreach ($tr->childNodes as $node) {
            if ($node->nodeName != 'td') {
                continue;
            }

            $className = $node->getAttribute('class');
            if (strpos($className, 'calendar__cell') === false) {
                continue;
            }

            $text = trim($node->textContent);
            if (strpos($className, 'calendar__date') !== false) {
                if ($text && preg_match('/.*[^0-9]([0-9]+)/', $text, $m2)) {
                    $dateDay = $m2[1];
                }
            } elseif (strpos($className, 'calendar__time') !== false) {
                if ($text && preg_match('/([0-9]{1,2}):([0-9]{1,2})\s*(am|pm)/', $text, $m2)) {
                    $eventHour = date("H:i", strtotime($text));
                    $eventDay = sprintf("%d.%02d.%02d %s", $year, $month, $dateDay, $eventHour);
                }
            } elseif (strpos($className, 'calendar__currency') !== false) {
                $currency = $text;
            } elseif (strpos($className, 'calendar__event') !== false) {
                $event = $text;
            } elseif (strpos($className, 'calendar__impact') !== false) {
                if (strpos($className, 'calendar__impact--low') !== false) {
                    $impact = 'low';
                } elseif (strpos($className, 'calendar__impact--medium') !== false) {
                    $impact = 'medium';
                } elseif (strpos($className, 'calendar__impact--high') !== false) {
                    $impact = 'high';
                }
            } elseif (strpos($className, 'calendar__actual') !== false) {
                $actual = $text;
            } elseif (strpos($className, 'calendar__forecast') !== false) {
                $forecast = $text;
            } elseif (strpos($className, 'calendar__previous') !== false) {
                $previous = $text;
            }
        }

        if(!array_key_exists($currency, $filterEvents)){
            continue;
        }

        if(!isset($options['nnfx-events']) || $options['nnfx-events']) {
            $found = false;
            foreach ($filterEvents[$currency] as $fevent) {
                if (strpos($event, $fevent) !== false) {
                    $found = true;
                    break;
                }
            }
            if (!$found) {
                echo "salta evento nao nnfx\n";
                continue;
            }
        }

        if(!empty($options['high-impact'])) {
            if ($impact != "high") {
                echo "salta nao é high impact\n";
                continue;
            }
        }

        $events[$currency][] = [
            $eventDay,
            $currency,
            $event,
            $impact,
            $actual,
            $forecast,
            $previous,
        ];
    }
}

$mq4 = file_get_contents('ind_template.mq4');
foreach($events as $currency => $ce){
    $mq4 .= "void load{$currency}(int limit, int buff){\n";
    $mq4 .= "   static __news_event source[] = {\n";
    foreach($ce as $ev){
        $mq4 .= "      {D'$ev[0]', \"$ev[2]\", 1},\n";
    }
    $mq4 .= "   };\n";
    $mq4 .= "   setNews(source, limit, buff);\n";
    $mq4 .= "};\n\n";
}

if(file_put_contents($argv[1], $mq4)){
    echo "generated file $argv[1]\n";
}
