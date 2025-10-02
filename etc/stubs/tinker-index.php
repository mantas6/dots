<?php

require __DIR__.'/vendor/autoload.php';

$app = require_once __DIR__.'/bootstrap/app.php';

$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);

$status = $kernel->handle(
    $input = new Symfony\Component\Console\Input\ArgvInput,
    new Symfony\Component\Console\Output\BufferedOutput
);

$result = null;
$definedVariables = [];
$definedVariables = array_keys(get_defined_vars());

$result = require './.tinker-buffer.php';

dump($result);
echo "\n";

$variables = array_filter(
    array: get_defined_vars(),
    callback: fn ($key) => !in_array($key, $definedVariables),
    mode: ARRAY_FILTER_USE_KEY
);

dump($variables);

$kernel->terminate($input, $status);
