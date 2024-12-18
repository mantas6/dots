# ssh

## Multiplexing

Speed up connection initiation times.

```
Host *
    ControlMaster auto
    ControlPath ~/.ssh/ssh_mux_%h_%p_%r
    ControlPersist 60m
```
