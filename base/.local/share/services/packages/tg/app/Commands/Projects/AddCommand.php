<?php

namespace App\Commands\Projects;

use App\Http\Integrations\Toggl\TogglConnector;
use App\Project;
use LaravelZero\Framework\Commands\Command;

use function Laravel\Prompts\search;

class AddCommand extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'projects:add';

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
        $items = (new TogglConnector)->projects()
            ->collect()
            ->mapWithKeys(fn (array $project) => [$project['id'] => $project['name']]);

        $selected = search(
            label: 'Select project',
            scroll: 20,
            options: fn (string $search) =>
                $items->filter(fn (string $name) => str($name)->contains($search, ignoreCase: true))
                ->toArray()
        );

        $project = Project::query()
            ->firstOrNew(['name' => $items[$selected]]);

        $project->ext_id = $selected;
        $project->save();
    }
}
