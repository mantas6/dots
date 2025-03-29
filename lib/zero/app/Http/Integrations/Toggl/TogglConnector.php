<?php

namespace App\Http\Integrations\Toggl;

use App\Http\Integrations\Toggl\Requests\ProjectsRequest;
use App\Http\Integrations\Toggl\Requests\TasksRequest;
use App\Project;
use App\Token;
use Saloon\Http\Auth\BasicAuthenticator;
use Saloon\Http\Connector;
use Saloon\Http\Response;
use Saloon\Traits\Plugins\AcceptsJson;
use Saloon\Traits\Plugins\AlwaysThrowOnErrors;

class TogglConnector extends Connector
{
    use AcceptsJson, AlwaysThrowOnErrors;

    protected string $token;
    protected string $workspaceId;

    public function __construct(string $tokenString = '')
    {
        if ($tokenString) {
            $this->token = $tokenString;

            return;
        }

        $token = Token::query()
            ->where('name', 'default')
            ->firstOrFail();

        $this->workspaceId = $token->default_workspace_id;
        $this->token = $token->contents;
    }

    public function projects(): Response
    {
        return $this->send(
            new ProjectsRequest($this->workspaceId)
        );
    }

    public function tasks(Project $project): Response
    {
        return $this->send(
            new TasksRequest($this->workspaceId, $project->ext_id)
        );
    }

    protected function defaultAuth(): BasicAuthenticator
    {
        return new BasicAuthenticator($this->token, 'api_token');
    }

    /**
     * The Base URL of the API
     */
    public function resolveBaseUrl(): string
    {
        return 'https://api.track.toggl.com/api/v9';
    }
}
