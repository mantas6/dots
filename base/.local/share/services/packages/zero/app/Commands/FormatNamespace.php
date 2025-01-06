<?php

namespace App\Commands;

use Illuminate\Support\Stringable;
use LaravelZero\Framework\Commands\Command;
use PhpParser\Error;
use PhpParser\Node\Name;
use PhpParser\Node\Stmt\Class_;
use PhpParser\Node\Stmt\ClassLike;
use PhpParser\Node\Stmt\Namespace_;
use PhpParser\NodeTraverser;
use PhpParser\NodeVisitor\CloningVisitor;
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

    protected array $autoloadPaths = [];
    protected string $basePath;

    /**
     * Execute the console command.
     */
    public function handle()
    {
        foreach ($this->argument('paths') as $path) {
            $this->basePath = $this->resolveBasePath(realpath($path));
            $this->autoloadPaths = $this->readAutoloadPaths();

            $this->formatFile(realpath($path));
        }
    }

    protected function formatFile(string $filePath): void
    {
        $parser = (new ParserFactory)->createForNewestSupportedVersion();
        $code = file_get_contents($filePath);

        $relativePath = str_replace($this->basePath . '/', '', $filePath);

        $originalAst = $parser->parse($code);
        $originalTokens = $parser->getTokens();

        $traverser = new NodeTraverser(new CloningVisitor);
        $ast = $traverser->traverse($originalAst);

        $this->formatAst($ast, $relativePath);

        $prettyPrinter = new Standard;
        $newCode = $prettyPrinter->printFormatPreserving($ast, $originalAst, $originalTokens);

        file_put_contents($filePath, $newCode);
    }

    protected function formatAst(array $ast, string $relativePath): void
    {
        $namespace = $ast[0];

        if ($namespace instanceof Namespace_) {
            $namespace->name->name = $this->convertPathToNamespace($relativePath);

            foreach ($namespace->stmts as $stmt) {
                if ($stmt instanceof ClassLike) {
                    $stmt->name->name = str($relativePath)
                        ->afterLast('/')
                        ->chopEnd('.php')
                        ->value();

                    break;
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

        return $composer['autoload']['psr-4'] ?? [];
    }

    protected function resolveBasePath(string $path): string
    {
        if (file_exists("$path/composer.json")) {
            return $path;
        }

        if ($path === '/') {
            return '';
        }

        return $this->resolveBasePath(
            dirname($path)
        );
    }
}
