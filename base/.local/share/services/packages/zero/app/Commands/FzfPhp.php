<?php

namespace App\Commands;

use App\Support\Fzf;
use Illuminate\Console\Scheduling\Schedule;
use LaravelZero\Framework\Commands\Command;
use Symfony\Component\Console\Color;
use Symfony\Component\Process\InputStream;
use Symfony\Component\Process\Process;

class FzfPhp extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'app:fzf-php';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Command description';

    /**
     * Execute the console command.
     */
    public function handle()
    {
        $options = array_fill(0, 100, '');

        $options = array_map(fn () => str()->random(50), $options);

        $reply = (new Fzf())
            ->options($options)
            ->run();
    }
}
