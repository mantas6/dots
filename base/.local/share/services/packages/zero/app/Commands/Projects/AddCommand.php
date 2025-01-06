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
            ->collect();

        $project = fzf(
            options: $items,
            present: fn (array $project) => [$project['name']],
        );

        if ($project) {
            return;
        }

        $project = Project::query()
            ->firstOrNew(['name' => $project['name']]);

        $project->ext_id = $project['id'];
        $project->save();
    }
}
