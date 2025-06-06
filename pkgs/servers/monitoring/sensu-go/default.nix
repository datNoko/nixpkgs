{
  buildGoModule,
  fetchFromGitHub,
  lib,
}:

let
  generic =
    {
      subPackages,
      pname,
      postInstall ? "",
      mainProgram,
    }:
    buildGoModule rec {
      inherit pname;
      version = "6.11.0";
      shortRev = "9587df6"; # for internal version info

      src = fetchFromGitHub {
        owner = "sensu";
        repo = "sensu-go";
        rev = "v${version}";
        sha256 = "sha256-Vcay8vUYLjV65g526btQX0+m5n/cRocIKx7C2LuWeP4=";
      };

      inherit subPackages postInstall;

      vendorHash = "sha256-ADqU/ZJiyZ5hAkqFXExmA8fSZxzhx42QptYu3TIlgBc=";

      patches = [
        # Without this, we get error messages like:
        # vendor/golang.org/x/sys/unix/mremap.go:41:10: unsafe.Slice requires go1.17 or later (-lang was set to go1.16; check go.mod)
        # The patch was generated by changing "go 1.16" to "go 1.21" and executing `go mod tidy`.
        ./fix-go-version-error.patch
      ];

      doCheck = false;

      ldflags =
        let
          versionPkg = "github.com/sensu/sensu-go/version";
        in
        [
          "-X ${versionPkg}.Version=${version}"
          "-X ${versionPkg}.BuildSHA=${shortRev}"
        ];

      meta = {
        inherit mainProgram;
        homepage = "https://sensu.io";
        description = "Open source monitoring tool for ephemeral infrastructure & distributed applications";
        license = lib.licenses.mit;
        maintainers = with lib.maintainers; [
          thefloweringash
          teutat3s
        ];
      };
    };
in
{
  sensu-go-cli = generic {
    pname = "sensu-go-cli";
    subPackages = [ "cmd/sensuctl" ];
    postInstall = ''
      mkdir -p \
        "''${!outputBin}/share/bash-completion/completions" \
        "''${!outputBin}/share/zsh/site-functions"

      ''${!outputBin}/bin/sensuctl completion bash > ''${!outputBin}/share/bash-completion/completions/sensuctl

      # https://github.com/sensu/sensu-go/issues/3132
      (
        echo "#compdef sensuctl"
        ''${!outputBin}/bin/sensuctl completion zsh
        echo '_complete sensuctl 2>/dev/null'
      ) > ''${!outputBin}/share/zsh/site-functions/_sensuctl

    '';
    mainProgram = "sensuctl";
  };

  sensu-go-backend = generic {
    pname = "sensu-go-backend";
    subPackages = [ "cmd/sensu-backend" ];
    mainProgram = "sensu-backend";
  };

  sensu-go-agent = generic {
    pname = "sensu-go-agent";
    subPackages = [ "cmd/sensu-agent" ];
    mainProgram = "sensu-agent";
  };
}
