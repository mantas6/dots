<?php

namespace App\Commands;

use App\Http\Integrations\Toggl\Requests\MeRequest;
use App\Http\Integrations\Toggl\TogglConnector;
use App\Token;
use LaravelZero\Framework\Commands\Command;

use function Laravel\Prompts\text;

class Authenticate extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'authenticate';

    protected $aliases = ['auth'];

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
        $token = Token::query()
            ->firstOrNew(['name' => 'default']);

        if ($token->isClean()) {
            $this->components->warn('Token is already defined');
        }

        $tokenString = text(
            label: 'Enter toggl token',
            required: true,
        );

        $connector = new TogglConnector($tokenString);

        $workspaceId = $connector->send(new MeRequest)
            ->json('default_workspace_id');

        $token->contents = $tokenString;
        $token->default_workspace_id = $workspaceId;
        $token->save();
    }
}
