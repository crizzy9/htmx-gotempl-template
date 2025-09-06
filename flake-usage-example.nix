# Example of how to use this template as a flake input in your NixOS configuration

{
  description = "My NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    
    # Add your HTMX Go Templ application as an input
    htmx-gotempl-app = {
      url = "github:youruser/your-htmx-gotempl-app";  # Replace with your repo
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, htmx-gotempl-app, ... }@inputs: {
    nixosConfigurations.your-server = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        # Import the HTMX Go Templ app module
        htmx-gotempl-app.nixosModules.default
        
        # Your configuration
        ({ config, pkgs, ... }: {
          # Enable the service
          services.htmx-gotempl-app = {
            enable = true;
            port = 8080;
            host = "0.0.0.0";
            openFirewall = true;
          };

          # Optional: nginx reverse proxy with SSL
          services.nginx = {
            enable = true;
            recommendedTlsSettings = true;
            recommendedOptimisation = true;
            recommendedGzipSettings = true;
            recommendedProxySettings = true;

            virtualHosts."your-domain.com" = {
              enableACME = true;
              forceSSL = true;
              
              locations."/" = {
                proxyPass = "http://127.0.0.1:8080";
                proxyWebsockets = true;
              };
            };
          };

          security.acme = {
            acceptTerms = true;
            defaults.email = "your-email@example.com";
          };

          networking.firewall.allowedTCPPorts = [ 80 443 ];

          # Your other system configuration...
        })
      ];
    };
  };
}