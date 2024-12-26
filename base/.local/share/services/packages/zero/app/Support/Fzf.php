<?php

namespace App\Support;

use Symfony\Component\Process\InputStream;
use Symfony\Component\Process\Process;

class Fzf
{
    protected array $options = [];
    protected array $command = [];

    public function __construct()
    {
       //
    }

    public function command(array $command): self
    {
        $this->command = $command;

        return $this;
    }

    public function options(array $options): self
    {
        $this->options = $options;

        return $this;
    }

    public function run(): string
    {
        $input = new InputStream();

        $process = new Process(
            command: ['fzf', ...$this->command],
            input: $input,
            timeout: 0,
        );

        $process->start();

        foreach ($this->options as $option) {
            $input->write("$option\n");
        }

        $input->close();

        $process->wait();

        return $process->getOutput();
    }
}
