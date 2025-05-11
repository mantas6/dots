<?php

namespace App\Commands\TimeEntries;

use App\TimeEntry;
use Illuminate\Console\Scheduling\Schedule;
use LaravelZero\Framework\Commands\Command;

class StopCommand extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'time:stop';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Stop tracking';

    /**
     * Execute the console command.
     */
    public function handle()
    {
        $runningEntry = TimeEntry::query()
            ->whereToday()
            ->whereNull('stopped_at')
            ->first();

        if ($runningEntry) {
            $runningEntry->update([
                'stopped_at' => now(),
            ]);
        }
    }

    /**
     * Define the command's schedule.
     */
    public function schedule(Schedule $schedule): void
    {
        // $schedule->command(static::class)->everyMinute();
    }
}
