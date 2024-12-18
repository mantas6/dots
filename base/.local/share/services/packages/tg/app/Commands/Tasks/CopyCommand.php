<?php

namespace App\Commands\Tasks;

use App\Http\Integrations\Toggl\TogglConnector;
use App\Project;
use App\Task;
use Illuminate\Contracts\Console\PromptsForMissingInput;
use Illuminate\Process\Pipe;
use Illuminate\Support\Facades\Process;
use Illuminate\Support\Facades\Storage;
use LaravelZero\Framework\Commands\Command;

class CopyCommand extends Command implements PromptsForMissingInput
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'tasks:cp {project-name} {--S|sync}';

    protected $aliases = ['cp'];

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
        if ($this->option('sync')) {
            $this->call(SyncCommand::class);
        }

        $tasks = Project::query()
            ->where('name', 'like', '%' . $this->argument('project-name') . '%')
            ->firstOrFail()
            ->tasks
            ->map(fn(Task $task) => $task->name);

        Storage::put('tasks', $tasks->join("\n"));

        $result = Process::pipe(function (Pipe $pipe) {
            $pipe->command('cat ' . Storage::path('tasks'));
            $pipe->command('fzf --tac');
            $pipe->command('xc');
        });
    }
}
