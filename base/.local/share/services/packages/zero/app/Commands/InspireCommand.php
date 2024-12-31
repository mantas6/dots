<?php

namespace App\Commands;

use Illuminate\Console\Scheduling\Schedule;
use LaravelZero\Framework\Commands\Command;
use Symfony\Component\Console\Helper\Table;
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
        $out = new BufferedOutput;
        $table = new Table($out);

        $rows = [
            [ 'title' => 'Oranges', 'id' => "\t1"],
            [ 'title' => 'Apples', 'id' => "\t2"],
            [ 'title' => 'Grapefruit', 'id' => "\t3"],
        ];

        $table->setStyle('compact')
            ->setRows($rows)
            ->render();

        $str = $out->fetch();

        $result = fzf(
            explode(PHP_EOL, $str),
            ['d' => "\t", 'with-nth' => '1'],
        );

        dd($result);
    }
}
