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

        $this->document .= '<style>'.$this->getStyle().'</style>';

        foreach (range($this->argument('start-num'), $this->argument('end-num')) as $num) {
            $url = str_replace('{}', $num, $this->argument('url'));
            $browser->request('GET', $url);

            $crawler = $browser->getCrawler();
            $crawler->filter('table table table table')
                ->each(function (Crawler $el) {
                    if (!str_contains($el->html(), 'bibl_knyga')) {
                        return;
                    }

                    $remove = [
                        '<tr align="left" valign="top"><td colspan="2" class="bibl_isnasa_vardas">Bibliografiniai duomenys:</td></tr><tr align="left" valign="top"><td colspan="2"><p>ŠVENTASIS RAŠTAS. Senasis ir Naujasis Testamentas. – Vilnius: Lietuvos Katalikų  Vyskupų Konferencija, 1998.</p> <p>© Lietuvos Vyskupų Konferencija, 1998. <a href="http://biblija.lt/index.aspx/lt_vertimai/leidimai/b_rk_k1998/">Išsamiai apie leidimą &gt;&gt;</a></p> </td> </tr>',
                        '<tr align="left" valign="top"><td colspan="2" class="bibl_isnasa_vardas">Bibliografiniai duomenys:</td></tr><tr align="left" valign="top"><td colspan="2" class="bibl_isnasa"><p>BIBLIJA arba ŠVENTASIS RAŠTAS. Ekumeninis leidimas. – Vilnius: Lietuvos Biblijos draugija, 1999.</p><p>© Lietuvos Biblijos draugija, 1999<br> © Lietuvos Vyskupų Konferencija, 1999. <a href="http://biblija.lt/index.aspx/lt_vertimai/leidimai/b_rk_e1999/">Išsamiai apie leidimą &gt;&gt;</a></p></td></tr>',
                    ];

                    $contents = str_replace($remove, '', $el->html());

                    $this->document .= '<table width="100%" border="0" cellspacing="2" a=""><tbody>'.$contents.'</tbody></table>';
                });
        }

        $this->line($this->document);
    }

    private function getStyle(): string
    {
        return file_get_contents(base_path('stubs/bible-style.css'));
    }
}
