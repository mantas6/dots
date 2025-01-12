<?php

namespace App\Commands\Projects;

use App\Http\Integrations\Toggl\TogglConnector;
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
        $connector = new TogglConnector;

        $response = $connector->projects();

        $response->collect()
            ->pluck('name')
            ->each(fn (string $name) => $this->line($name));
    }
}
