<?php

namespace App\Http\Integrations\Toggl;

use Saloon\Http\Auth\BasicAuthenticator;
use Saloon\Http\Connector;
use Saloon\Traits\Body\HasJsonBody;
use Saloon\Traits\Plugins\AcceptsJson;

class TogglConnector extends Connector
{
    use AcceptsJson;

    public function __construct(
        public readonly string $token,
    ){}

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

    /**
     * Default headers for every request
     */
    protected function defaultHeaders(): array
    {
        return [];
    }

    /**
     * Default HTTP client options
     */
    protected function defaultConfig(): array
    {
        return [];
    }
}
