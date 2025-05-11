<?php

namespace App\Commands\TimeEntries;

use Illuminate\Console\Scheduling\Schedule;
use LaravelZero\Framework\Commands\Command;

class PushCommand extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'time:push';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Synchronize data with remote';

    /**
     * Execute the console command.
     */
    public function handle()
    {
        //
    }

    /**
     * Define the command's schedule.
     */
    public function schedule(Schedule $schedule): void
    {
        // $schedule->command(static::class)->everyMinute();
    }
}
