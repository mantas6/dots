<?php

namespace App\Commands\Projects;

use App\Http\Integrations\Toggl\TogglConnector;
use App\Project;
use LaravelZero\Framework\Commands\Command;

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

        $selected = fzf(
            options: $items,
            present: fn (array $project) => [$project['name']],
        );

        if (!$selected) {
            return;
        }

        $project = Project::query()
            ->firstOrNew(['name' => $selected['name']]);

        $project->ext_id = $selected['id'];
        $project->save();
    }
}
