<?php

namespace App\Providers;

use Illuminate\Support\ServiceProvider;
use Mantas6\FzfPhp\FuzzyFinder;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        // FuzzyFinder::usingCommand('/usr/bin/env fzf');
    }

    /**
     * Register any application services.
     */
    public function register(): void
    {
        //
    }
}
