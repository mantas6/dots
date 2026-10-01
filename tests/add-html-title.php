<?php
// Run with: php tests/add-html-title.php (requires the DOM extension).

$titles = ['example.php', 'foo&bar.php', 'a&amp;b.php', '<tag> "quoted".php', ''];

foreach ($titles as $title) {
    $file = tempnam(__DIR__, '.add-html-title-');

    try {
        file_put_contents($file, '<!DOCTYPE html><html><body style="color: red"><pre>original code</pre></body></html>');
        $process = proc_open(
            [PHP_BINARY, __DIR__ . '/../bin/add-html-title', $file, $title],
            [1 => ['pipe', 'w'], 2 => ['pipe', 'w']],
            $pipes,
        );
        $stdout = stream_get_contents($pipes[1]);
        $stderr = stream_get_contents($pipes[2]);
        fclose($pipes[1]);
        fclose($pipes[2]);
        $status = proc_close($process);

        if ($status !== 0 || $stdout !== '' || $stderr !== '') {
            throw new RuntimeException("Script failed for '$title': $status $stdout $stderr");
        }

        $dom = new DOMDocument();
        $dom->loadHTML(file_get_contents($file));
        $body = $dom->getElementsByTagName('body')->item(0);
        $h1 = $dom->getElementsByTagName('h1')->item(0);

        if ($h1 === null || $h1->textContent !== strtoupper($title)) {
            throw new RuntimeException("Title was not preserved literally: '$title'");
        }
        if ($h1->getAttribute('align') !== 'center' || $h1->childElementCount !== 0) {
            throw new RuntimeException('Heading alignment or literal text changed');
        }
        if ($body->firstElementChild !== $h1 || $h1->nextElementSibling->tagName !== 'hr') {
            throw new RuntimeException('Heading and separator are not before the code');
        }
        if ($body->hasAttribute('style') || $dom->getElementsByTagName('pre')->item(0)->textContent !== 'original code') {
            throw new RuntimeException('Body style removal or original code changed');
        }
    } finally {
        unlink($file);
    }
}

printf("Passed %d add-html-title cases\n", count($titles));
