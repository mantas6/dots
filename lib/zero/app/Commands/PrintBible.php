<?php

namespace App\Commands;

use LaravelZero\Framework\Commands\Command;
use Symfony\Component\BrowserKit\HttpBrowser;
use Symfony\Component\DomCrawler\Crawler;

class PrintBible extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'app:print-bible {url} {start-num} {end-num}';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Command description';

    protected string $document = '';

    /**
     * Execute the console command.
     */
    public function handle()
    {
        $browser = new HttpBrowser;

        foreach (range($this->argument('start-num'), $this->argument('end-num')) as $num) {
            $url = str_replace('{}', $num, $this->argument('url'));
            $browser->request('GET', $url);

            $crawler = $browser->getCrawler();
            $crawler->filter('table table table table')
                ->each(function (Crawler $el) {
                    if (!str_contains($el->html(), 'bibl_knyga')) {
                        return;
                    }

                    $this->document .= '<table width="100%" border="0" cellspacing="2" a=""><tbody>' . $el->html() . '</tbody></table>';
                });
        }

        $this->line($this->document);
    }
}
