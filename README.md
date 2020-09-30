# nnfx-news
Generator of mq4 indicator with historical news from forexfactory.con

## Requirements:

* PHP 5 or above

## How to Use:

To Build the news indicator it must be done in 2 steps: download news and generate indicator.

* Extract this repository to a folder like nnfx-news
* In command line, donwload news by execute the command: `php download-news.php`
* Generate mq4 indicator, execute: `php generate_indicator.php NNFX_News_offline.mq4`

After 

> Note: If the php command is not recognized in line command, you can especify the full path of php.exe, like `C:\xampp\php\php.exe download-news.php`

## Options for generator:

The `generate_indicator.php` script only generate specific events for NNFX use referred to by the VP.

Instead of this filter events, it is possible to generate indicator with all high-impact events.
To do this, you can run command like:

`php generate_indicator.php HighImpact_News_offline.mq4 --nnfx-events=0 --high-impact=1`

## NNFX events:

In ´generate_indicator.php´ there are the list of expressions to filter events for nnfx use:

```php
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
```