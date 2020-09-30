<?php
/**
 * Created by cryptek.
 * Date: 30/09/2020
 * Time: 10:07
 */

$newsPath = "news";
if(!is_dir($newsPath)){
    mkdir($newsPath);
}

$from = '2010-01-01';
$to = date('Y-m-d');

$toDate = new DateTime($to);
$date = new DateTime($from);
if($date >= $toDate){
    echo "error {$year}_{$month}.html\n";
    return;
}

echo "fetch all news from forexfactory.com from " . $date->format('Y-M') . " to " . $toDate->format('Y-M') . " on folder '" . $newsPath . "'\n";

while($date <= $toDate){
    $year = $date->format('Y');
    $month = $date->format('m');
    $monthText = strtolower($date->format('M'));
    $file = "{$year}_{$month}.html";
    $opts = [
        'http'=>[
            'method' => "GET",
            'header' => "Accept-language: en\r\n" .
                "cookie: ffdstonoff=0; fftimezoneoffset=0; ffverifytimes=1;\r\n"
        ]
    ];
    $context = stream_context_create($opts);
    $html = file_get_contents('https://www.forexfactory.com/calendar?month='.$monthText.'.'.$year, false, $context);
    if($html){
        file_put_contents("{$newsPath}/{$file}", $html);
        echo "save {$year}_{$month}.html\n";
    }
    else {
        echo "error {$year}_{$month}.html\n";
        return;
    }
    sleep(3);
    $date->modify('+1 month');
}