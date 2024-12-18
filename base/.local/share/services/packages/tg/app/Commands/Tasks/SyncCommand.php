<?php

namespace App\Commands\Tasks;

use App\Http\Integrations\Toggl\TogglConnector;
use App\Project;
use App\Task;
use LaravelZero\Framework\Commands\Command;

use function Laravel\Prompts\search;

class SyncCommand extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'tasks:sync';

    protected $aliases = ['sync', 'y'];

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
        foreach (Project::all() as $project) {
            (new TogglConnector)
                ->tasks($project)
                ->collect()
                ->each(function (array $item) use ($project) {
                    $task = $project->tasks()
                        ->firstOrNew(['ext_id' => $item['id']]);

                    $task->name = $item['name'];
                    $task->save();
                })
                ->tap(fn ($items) => $this->components->twoColumnDetail($project->name, count($items)));
        }
    }
}
