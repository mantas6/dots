<?php

namespace App\Commands\TimeEntries;

use App\Task;
use App\TimeEntry;
use Illuminate\Console\Scheduling\Schedule;
use LaravelZero\Framework\Commands\Command;

class StartCommand extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'time:start {task-id}';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Start a timer';

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

        // Task::query()
        //     ->where(

        TimeEntry::create([
            'started_at' => now(),
            'task_id' => $this->argument('task-id'),
        ]);
    }

    /**
     * Define the command's schedule.
     */
    public function schedule(Schedule $schedule): void
    {
        // $schedule->command(static::class)->everyMinute();
    }
}
