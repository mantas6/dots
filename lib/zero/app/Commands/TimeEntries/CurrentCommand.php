<?php

namespace App\Commands\TimeEntries;

use App\TimeEntry;
use Illuminate\Console\Scheduling\Schedule;
use LaravelZero\Framework\Commands\Command;

class CurrentCommand extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'time:current';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Display current task name';

    /**
     * Execute the console command.
     */
    public function handle()
    {
        $runningEntry = TimeEntry::query()
            ->whereToday()
            ->whereNull('stopped_at')
            ->first();

        $this->line($runningEntry->task()->name);
    }

    /**
     * Define the command's schedule.
     */
    public function schedule(Schedule $schedule): void
    {
        // $schedule->command(static::class)->everyMinute();
    }
}
