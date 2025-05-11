<?php

namespace App\Commands\TimeEntries;

use App\TimeEntry;
use Illuminate\Console\Scheduling\Schedule;
use LaravelZero\Framework\Commands\Command;

class ListCommand extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'time:list';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'List time entries';

    /**
     * Execute the console command.
     */
    public function handle()
    {
        $entries = TimeEntry::query()
            ->whereToday()
            ->get()
            ->map(fn (TimeEntry $entry) => [
                $entry->task->name,
                $entry->started_at,
                $entry->stopped_at,
                $entry->started_at->diffForHumans($entry->stopped_at ?: now()),
            ])
            ->all();

        $this->table(
            headers: [],
            rows: $entries,
            tableStyle: 'compact',
        );
    }
}
