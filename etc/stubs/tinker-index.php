<?php

require __DIR__.'/vendor/autoload.php';

$app = require_once __DIR__.'/bootstrap/app.php';

$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);

$status = $kernel->handle(
   $input = new Symfony\Component\Console\Input\ArgvInput,
    new Symfony\Component\Console\Output\BufferedOutput
);

$result = require './.tinker-buffer.php';

dump($result);

$kernel->terminate($input, $status);
