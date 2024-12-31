<?php

namespace App\Commands;

use Illuminate\Console\Scheduling\Schedule;
use LaravelZero\Framework\Commands\Command;
use Symfony\Component\Console\Helper\Table;
use Symfony\Component\Console\Helper\TableCell;
use Symfony\Component\Console\Helper\TableCellStyle;
use Symfony\Component\Console\Output\BufferedOutput;

use function Mantas6\FzfPhp\fzf;
use function Termwind\render;

class InspireCommand extends Command
{
    /**
     * The signature of the command.
     *
     * @var string
     */
    protected $signature = 'inspire';

    /**
     * The description of the command.
     *
     * @var string
     */
    protected $description = 'Display an inspiring quote';

    /**
     * Execute the console command.
     */
    public function handle(): void
    {
        $out = new BufferedOutput(decorated: true);
        $table = new Table($out);

        $rows = [
            ['a' => '100', 'title' => "::Oranges", 'id' => "1", 'abc' => new TableCell('Testas', options: [
                'style' => new TableCellStyle(['fg' => 'red'])
            ])],
            ['a' => '201', 'title' => "::Apples", 'id' => "2", 'abc' => ''],
            ['a' => '300', 'title' => "::Grapefruit", 'id' => "3", 'abc' => ''],
        ];

        $table->setStyle('compact')
            ->setRows($rows)
            ->render();

        $str = $out->fetch();

        $result = fzf(
            explode(PHP_EOL, $str),
            [
                'd' => "::",
                'with-nth' => '2..',
                'ansi' => true,
            ],
        );

        dd($result);
    }
}
