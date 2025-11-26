<?php

declare(strict_types=1);

namespace App\Commands;

use Exception;
use LaravelZero\Framework\Commands\Command;
use PhpParser\Node\Name;
use PhpParser\Node\Stmt\ClassLike;
use PhpParser\Node\Stmt\Namespace_;
use PhpParser\NodeTraverser;
use PhpParser\NodeVisitor\CloningVisitor;
use PhpParser\Parser;
use PhpParser\ParserFactory;
use PhpParser\PrettyPrinter\Standard;

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

    protected Parser $parser;
    protected Standard $printer;

    protected array $autoloadPaths = [];
    protected string $basePath;

    /**
     * Execute the console command.
     */
    public function handle()
    {
        $this->parser = (new ParserFactory)->createForNewestSupportedVersion();
        $this->printer = new Standard;

        foreach ($this->argument('paths') as $path) {
            $fullPath = realpath($path);

            $this->basePath = $this->resolveBasePath($fullPath);
            $this->autoloadPaths = $this->readAutoloadPaths();

            $this->formatFile($fullPath);
        }
    }

    protected function formatFile(string $filePath): void
    {
        $code = file_get_contents($filePath);

        if (trim($code) === '') {
            $code = file_get_contents(base_path('stubs/PhpClass.stub'));
        }

        $relativePath = str_replace($this->basePath . '/', '', $filePath);

        $originalAst = $this->parser->parse($code);
        $originalTokens = $this->parser->getTokens();

        $traverser = new NodeTraverser(new CloningVisitor);
        $ast = $traverser->traverse($originalAst);

        $this->formatAst($ast, $relativePath);

        $newCode = $this->printer->printFormatPreserving($ast, $originalAst, $originalTokens);

        file_put_contents($filePath, $newCode);
    }

    protected function formatAst(array $ast, string $relativePath): void
    {
        foreach ($ast as $item) {
            if ($item instanceof Namespace_) {
                $item->name->name = $this->convertPathToNamespace($relativePath);

                foreach ($item->stmts as $stmt) {
                    if ($stmt instanceof ClassLike) {
                        $stmt->name->name = str($relativePath)
                            ->afterLast('/')
                            ->chopEnd('.php')
                            ->value();

                        return;
                    }
                }
            }
        }
    }

    protected function convertPathToNamespace(string $relativePath): string
    {
        $str = str($relativePath);

        foreach ($this->autoloadPaths as $namespace => $path) {
            $str = $str->replaceStart($path, $namespace);
        }

        return $str->chopEnd('.php')
            ->beforeLast('/')
            ->replace('/', '\\')
            ->value();
    }

    protected function readAutoloadPaths(): array
    {
        $composer = json_decode(
            file_get_contents($this->basePath . '/composer.json'),
            true,
        );

        return [
            ...$composer['autoload']['psr-4'] ?? [],
            ...$composer['autoload-dev']['psr-4'] ?? [],
        ];
    }

    protected function resolveBasePath(string $path): string
    {
        if (file_exists("$path/composer.json")) {
            return $path;
        }

        if ($path === '/') {
            throw new Exception('No composer.json has been found');
        }

        return $this->resolveBasePath(
            dirname($path)
        );
    }
}
