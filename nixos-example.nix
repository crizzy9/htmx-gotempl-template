# Example NixOS configuration for self-hosting the HTMX Go Templ application
# Add this to your NixOS configuration.nix or import as a separate module

{ config, pkgs, ... }:

{
  # Import the flake as an input (add to your flake.nix inputs)
  # inputs.htmx-gotempl-template.url = "github:youruser/your-repo";
  
  # Import the module
  imports = [
    # Assuming you've added the flake as an input:
    # inputs.htmx-gotempl-template.nixosModules.default
    
    # Or if using this template directly:
    ./flake.nix
  ];

  # Enable the service
  services.htmx-gotempl-app = {
    enable = true;
    port = 8080;
    host = "0.0.0.0";
    openFirewall = true;
  };

  # Optional: Set up nginx reverse proxy
  services.nginx = {
    enable = true;
    recommendedTlsSettings = true;
    recommendedOptimisation = true;
    recommendedGzipSettings = true;
    recommendedProxySettings = true;

    virtualHosts."your-domain.com" = {
      # Enable SSL with Let's Encrypt
      enableACME = true;
      forceSSL = true;
      
      locations."/" = {
        proxyPass = "http://127.0.0.1:8080";
        proxyWebsockets = true;
        extraConfig = ''
          proxy_set_header Host $host;
          proxy_set_header X-Real-IP $remote_addr;
          proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
          proxy_set_header X-Forwarded-Proto $scheme;
        '';
      };
    };
  };

  # Let's Encrypt configuration
  security.acme = {
    acceptTerms = true;
    defaults.email = "your-email@example.com";
  };

  # Open firewall for HTTP/HTTPS
  networking.firewall.allowedTCPPorts = [ 80 443 ];
}