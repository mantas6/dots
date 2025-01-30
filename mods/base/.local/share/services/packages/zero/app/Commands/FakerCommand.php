<?php

namespace App\Commands;

use Illuminate\Console\Scheduling\Schedule;
use LaravelZero\Framework\Commands\Command;

class FakerCommand extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'app:faker {cmd} {args?*} {--count=1} {--locale=en}';

    protected $aliases = ['fake'];

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
        $cmd = $this->argument('cmd');
        $args = $this->argument('args');
        $count = $this->option('count');
        $locale = $this->option('locale');

        foreach (range(1, $count) as $_) {
            $this->output->writeLn(
                fake($locale)->{$cmd}(...$args)
            );
        }
    }
}
