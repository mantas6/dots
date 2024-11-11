<?php

namespace App\Commands\Projects;

use App\Http\Integrations\Toggl\Requests\MeRequest;
use App\Http\Integrations\Toggl\Requests\ProjectsRequest;
use App\Http\Integrations\Toggl\TogglConnector;
use Illuminate\Console\Scheduling\Schedule;
use LaravelZero\Framework\Commands\Command;

class ListCommand extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'projects:list';

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
        $connector = new TogglConnector(env('TOGGL_API_TOKEN'));

        $workspaceId = $connector->send(new MeRequest)
            ->json('default_workspace_id');

        $response = $connector->send(new ProjectsRequest($workspaceId));

        dd($response->collect()->pluck('name'));
    }
}
