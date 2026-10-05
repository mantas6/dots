<?php
// Run with: php tests/merge-html.php (requires the DOM extension).

declare(strict_types=1);

$cases = [
    'missing head' => ['<html><body><p>first</p></body></html>', true, false],
    'body fragment' => ['<p>first</p>', true, false],
    'existing head' => ['<html><head><title>Original</title><style>p{color:blue}</style></head><body><p>first</p></body></html>', true, true],
    'no styles' => ['<p>first</p>', false, false],
];

foreach ($cases as $name => [$first, $withStyles, $existingHead]) {
    $files = [tempnam(__DIR__, '.merge-html-'), tempnam(__DIR__, '.merge-html-')];

    try {
        file_put_contents($files[0], $first);
        $styles = $withStyles ? '<style>p{color:red}</style><link rel="stylesheet" href="second.css">' : '';
        $second = '<html><head><title>Ignored</title><meta name="author" content="Ignored"><script>ignored()</script><link rel="icon" href="ignored.ico">'.$styles.'</head><body><p>second</p></body></html>';
        file_put_contents($files[1], $second);
        $process = proc_open(
            [PHP_BINARY, __DIR__.'/../bin/merge-html', ...$files],
            [1 => ['pipe', 'w'], 2 => ['pipe', 'w']],
            $pipes,
        );
        $stdout = stream_get_contents($pipes[1]);
        $stderr = stream_get_contents($pipes[2]);
        fclose($pipes[1]);
        fclose($pipes[2]);
        $status = proc_close($process);

        if ($status !== 0 || $stderr !== '') {
            throw new RuntimeException("Script failed for $name: $status $stderr");
        }

        $dom = new DOMDocument;
        $dom->loadHTML($stdout);
        $xpath = new DOMXPath($dom);
        $styleNodes = $xpath->query('/html/head/style');
        $expectedStyles = $withStyles ? ($existingHead ? 2 : 1) : 0;
        if ($styleNodes->length !== $expectedStyles
            || ($withStyles && $styleNodes->item($expectedStyles - 1)->textContent !== 'p{color:red}')
            || ($existingHead && $styleNodes->item(0)->textContent !== 'p{color:blue}')
            || $xpath->query('/html/head/link[@rel="stylesheet" and @href="second.css"]')->length !== (int) $withStyles
        ) {
            throw new RuntimeException("Styles were not preserved for $name");
        }
        if ($xpath->query('/html/head')->length !== (int) ($withStyles || $existingHead)
            || $xpath->query('/html/head/following-sibling::body')->length !== (int) ($withStyles || $existingHead)
            || $xpath->query('//meta | //script | //link[@rel="icon"]')->length !== 0
            || $xpath->query('//title')->length !== (int) $existingHead
            || ($existingHead && $xpath->evaluate('string(/html/head/title)') !== 'Original')
        ) {
            throw new RuntimeException("Head placement or metadata selection changed for $name");
        }
        if ($xpath->evaluate('string(/html/body/p[1])') !== 'first'
            || $xpath->evaluate('string(/html/body/p[2])') !== 'second'
            || $xpath->query('/html/body/p[1]/following-sibling::*[1][self::hr]')->length !== 1
            || $xpath->query('/html/body/hr')->length !== 1
        ) {
            throw new RuntimeException("Body ordering changed for $name");
        }
        foreach ($files as $i => $file) {
            if (file_get_contents($file) !== ($i === 0 ? $first : $second)) {
                throw new RuntimeException("Input file changed for $name");
            }
        }
    } finally {
        foreach ($files as $file) {
            unlink($file);
        }
    }
}

printf("Passed %d merge-html cases\n", count($cases));
