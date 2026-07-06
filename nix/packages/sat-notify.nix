{...}: {
  perSystem = {pkgs, ...}: {
    packages.sat-notify = pkgs.writeShellApplication {
      name = "sat-notify";
      runtimeInputs = [pkgs.curl pkgs.coreutils];
      text = ''
        message="$1"
        expire='+2 days'

        state_home=''${XDG_STATE_HOME:-"$HOME/.local/state"}
        state=''${SAT_JOURNAL_STATE:-"$state_home/sat"}

        if [ ! -f "$state/url" ]; then
          echo 'Error: URL is not configured. Use sat-login command to enter it.' >&2
          exit 1
        fi

        if [ ! -f "$state/token" ]; then
          echo 'Error: Token is not configured' >&2
          exit 1
        fi

        url=$(<"$state/url")
        token=$(<"$state/token")

        curl -fsSLX POST \
          -d "message=$message" \
          -d "expire=$expire" \
          -H "Authorization: Bearer $token" \
          "$url/api/notify"

        exit 0
      '';
    };
  };
}
