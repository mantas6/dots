{...}: {
  imports = [
    ./nfs
    ./ssh.nix
    ./store.nix
    ./docker.nix
    ./other.nix
  ];
}
