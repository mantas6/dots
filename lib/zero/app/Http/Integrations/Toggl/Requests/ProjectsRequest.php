<?php

namespace App\Http\Integrations\Toggl\Requests;

use Saloon\Enums\Method;
use Saloon\Http\Request;

class ProjectsRequest extends Request
{
    /**
     * The HTTP method of the request
     */
    protected Method $method = Method::GET;

    public function __construct(
        protected readonly string $workspaceId,
    ) {}

    /**
     * The endpoint for the request
     */
    public function resolveEndpoint(): string
    {
        return '/workspaces/'.$this->workspaceId.'/projects';
    }
}
