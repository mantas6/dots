<?php

namespace App\Commands;

use LaravelZero\Framework\Commands\Command;
use PhpParser\Error;
use PhpParser\NodeTraverser;
use PhpParser\NodeVisitorAbstract;
use PhpParser\ParserFactory;
use PhpParser\Node;
use PhpParser\Node\Name\FullyQualified;

class FormatNamespace extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'app:format-namespace {paths*}';

    protected $aliases = ['fmt'];

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
        foreach ($this->argument('paths') as $path) {
            $this->formatFilePath($path);
        }
    }

    protected function formatFilePath(string $filePath): void
    {
        $parser = (new ParserFactory())->createForNewestSupportedVersion();
        $code = file_get_contents($filePath);

        try {
            $ast = $parser->parse($code);
        } catch (Error $error) {
            echo "Parse error: {$error->getMessage()}\n";
            return;
        }

        $traverser = new NodeTraverser;
        $traverser->addVisitor(new class extends NodeVisitorAbstract {
            public function leaveNode(Node $node)
            {
                if ($node instanceof FullyQualified)
                dump($node);
            }
        });

        $traverser->traverse($ast);
    }
}
