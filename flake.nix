{
  description = "HTMX Go Templ web application";

  inputs.nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/0.1.*.tar.gz";

  outputs = { self, nixpkgs }:
    let
      goVersion = 23; # Go 1.23 to match current setup

      supportedSystems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      forEachSupportedSystem = f: nixpkgs.lib.genAttrs supportedSystems (system: f {
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ self.overlays.default ];
        };
      });

      # Build the application
      mkApp = { pkgs, system }: pkgs.buildGoModule {
        pname = "htmx-gotempl-app";
        version = "0.1.0";
        
        src = ./.;
        
        vendorHash = "sha256-4zBOk169vEKZLPycHlGysmlyQibrTls43e7btDvbAcQ=";
        
        nativeBuildInputs = with pkgs; [ templ ];
        
        preBuild = ''
          templ generate
        '';
        
        buildInputs = with pkgs; [ ];
        
        # Copy static files
        postInstall = ''
          mkdir -p $out/share/htmx-gotempl-app
          cp -r web $out/share/htmx-gotempl-app/
        '';
        
        meta = with pkgs.lib; {
          description = "HTMX Go Templ web application";
          homepage = "https://github.com/example/htmx-gotempl-template";
          license = licenses.mit;
          maintainers = [ ];
        };
      };
    in
    {
      overlays.default = final: prev: {
        go = final."go_1_${toString goVersion}";
        htmx-gotempl-app = mkApp { pkgs = final; system = final.system; };
      };

      packages = forEachSupportedSystem ({ pkgs }: {
        default = mkApp { inherit pkgs; system = pkgs.system; };
        htmx-gotempl-app = mkApp { inherit pkgs; system = pkgs.system; };
      });

      apps = forEachSupportedSystem ({ pkgs }: {
        default = {
          type = "app";
          program = "${self.packages.${pkgs.system}.default}/bin/main";
        };
      });

      devShells = forEachSupportedSystem ({ pkgs }: {
        default = pkgs.mkShell {
          packages = with pkgs; [
            # go (version is specified by overlay)
            go

            # goimports, godoc, etc.
            gotools

            # https://github.com/golangci/golangci-lint
            golangci-lint

            # Templ templating library
            templ
          ];
        };
      });

      # NixOS module for easy deployment
      nixosModules.default = { config, lib, pkgs, ... }:
        let
          cfg = config.services.htmx-gotempl-app;
          pkg = self.packages.${pkgs.system}.default;
        in
        {
          options.services.htmx-gotempl-app = {
            enable = lib.mkEnableOption "HTMX Go Templ application";
            
            port = lib.mkOption {
              type = lib.types.port;
              default = 8080;
              description = "Port to listen on";
            };
            
            host = lib.mkOption {
              type = lib.types.str;
              default = "0.0.0.0";
              description = "Host to bind to";
            };
            
            user = lib.mkOption {
              type = lib.types.str;
              default = "htmx-gotempl-app";
              description = "User to run the service as";
            };
            
            group = lib.mkOption {
              type = lib.types.str;
              default = "htmx-gotempl-app";
              description = "Group to run the service as";
            };
            
            openFirewall = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = "Whether to open the firewall for the application port";
            };
          };
          
          config = lib.mkIf cfg.enable {
            users.users.${cfg.user} = {
              isSystemUser = true;
              group = cfg.group;
              description = "HTMX Go Templ application user";
            };
            
            users.groups.${cfg.group} = {};
            
            systemd.services.htmx-gotempl-app = {
              description = "HTMX Go Templ web application";
              after = [ "network.target" ];
              wantedBy = [ "multi-user.target" ];
              
              environment = {
                APP_PORT = toString cfg.port;
                APP_HOST = cfg.host;
              };
              
              serviceConfig = {
                Type = "simple";
                User = cfg.user;
                Group = cfg.group;
                ExecStart = "${pkg}/bin/main";
                WorkingDirectory = "${pkg}/share/htmx-gotempl-app";
                Restart = "always";
                RestartSec = "10";
                
                # Security settings
                NoNewPrivileges = true;
                PrivateTmp = true;
                ProtectSystem = "strict";
                ProtectHome = true;
                ProtectKernelTunables = true;
                ProtectKernelModules = true;
                ProtectControlGroups = true;
                RestrictAddressFamilies = [ "AF_UNIX" "AF_INET" "AF_INET6" ];
                RestrictNamespaces = true;
                LockPersonality = true;
                MemoryDenyWriteExecute = true;
                RestrictRealtime = true;
                RestrictSUIDSGID = true;
                RemoveIPC = true;
              };
            };
            
            networking.firewall.allowedTCPPorts = lib.mkIf cfg.openFirewall [ cfg.port ];
          };
        };
    };
}
