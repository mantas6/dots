<?php

namespace App\Commands\Projects;

use App\Http\Integrations\Toggl\TogglConnector;
use App\Project;
use LaravelZero\Framework\Commands\Command;

use function Laravel\Prompts\search;
use function Mantas6\FzfPhp\fzf;

class AddCommand extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'projects:add';

    protected $aliases = ['add'];

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

        $selected = fzf(
            options: $items->map(fn ($name, $id) => "$id:$name")
                ->toArray(),

            arguments: [
                'delimiter' => ':',
                'with-nth' => '2',
            ],
        );

        $index = str($selected)->before(':')->toString();

        $project = Project::query()
            ->firstOrNew(['name' => $items[$index]]);

        $project->ext_id = $index;
        $project->save();
    }
}
