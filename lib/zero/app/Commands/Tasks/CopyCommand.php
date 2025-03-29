<?php

namespace App\Commands\Tasks;

use App\Project;
use App\Task;
use Illuminate\Contracts\Console\PromptsForMissingInput;
use Illuminate\Support\Facades\Process;
use LaravelZero\Framework\Commands\Command;

use function Mantas6\FzfPhp\fzf;

class CopyCommand extends Command implements PromptsForMissingInput
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'tasks:cp {project-name} {--y|sync}';

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
            $this->call(SyncCommand::class, [
                'project-name' => $this->argument('project-name'),
            ]);
        }

        $tasks = Project::query()
            ->where('name', 'like', '%'.$this->argument('project-name').'%')
            ->firstOrFail()
            ->tasks;

        $task = fzf(
            options: $tasks,
            arguments: ['tac' => true],
            present: fn (Task $task) => [$task->name],
        );

        Process::input($task->name)->run('xc');
    }
}
