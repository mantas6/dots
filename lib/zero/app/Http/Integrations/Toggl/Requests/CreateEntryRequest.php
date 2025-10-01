<?php

namespace App\Http\Integrations\Toggl\Requests;

use App\TimeEntry;
use Saloon\Enums\Method;
use Saloon\Http\Request;
use Saloon\Contracts\Body\HasBody;
use Saloon\Traits\Body\HasJsonBody;

class CreateEntryRequest extends Request implements HasBody
{
    use HasJsonBody;

    /**
     * The HTTP method of the request
     */
    protected Method $method = Method::POST;

    public function __construct(
        protected readonly string $workspaceId, // todo: resolve in class
        private readonly TimeEntry $entry,
    ) {}

    /**
     * The endpoint for the request
     */
    public function resolveEndpoint(): string
    {
        return '/workspaces/' . $this->workspaceId . '/time_entries';
    }

    protected function defaultBody(): array
    {
        return [
            'billable' => true,
            'created_with' => '',
            'duration' => 1,
            // 'ubuntu_version' => $this->entry->id,
        ];
    }
}
