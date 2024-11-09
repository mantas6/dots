<?php

namespace App\Commands;

use App\Http\Integrations\Toggl\Requests\MeRequest;
use App\Http\Integrations\Toggl\TogglConnector;
use Illuminate\Console\Scheduling\Schedule;
use LaravelZero\Framework\Commands\Command;

class ProjectList extends Command
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
        $connector = new TogglConnector('abc');

        $response = $connector->send(new MeRequest);
    }
}
