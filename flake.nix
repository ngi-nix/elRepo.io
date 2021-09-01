{
  description = "RetroShare";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-21.05";
    retroshare-src = {
      url = "https://gitlab.com/retroshare/retroshare";
      type = "git";
      flake = false;
      submodules = true;
    };
  };


  outputs = { self, nixpkgs, retroshare-src, ... }:
    let
      supportedSystems = [ "x86_64-linux" "x86_64-darwin" ];
      forAllSystems = f: nixpkgs.lib.genAttrs supportedSystems (system: f system);

      nixpkgsFor = forAllSystems (system:
        import nixpkgs {
          inherit system;
          overlays = [ self.overlay ];
        }
      );

      majorVersion = "0";
      minorVersion = "6";
      miniVersion = "6";
      extraVersion = "-71-g8bed99cc9";

    in
    {

      overlay = super: self: {

        retroshare = super.stdenv.mkDerivation rec {
          name = "retroshare-${version}";
          version = "0.1.0";
          src = retroshare-src;

          nativeBuildInputs = with super; [
            sqlcipher
            sqlite
            pkg-config
            libupnp
          ] ++ (with super.qt5; [
            qtmultimedia
            qtx11extras
            qttools
            wrapQtAppsHook
            qmake
          ]);
          buildInputs = with super; [
            cmake
            openssl
            bzip2
            xapian
            rapidjson
            xorg.libXScrnSaver
            xorg.libxcb
          ];

          buildPhase = ''
            qmake \
              PREFIX=/$out \
              "CONFIG-=debug" \
              "CONFIG+=no_direct_chat" \
              "CONFIG+=no_retroshare_android_service" \
              "CONFIG+=no_retroshare_android_notify_service" \
              "CONFIG+=release" \
              RS_MAJOR_VERSION+=${majorVersion} \
              RS_MINOR_VERSION+=${minorVersion} \
              RS_MINI_VERSION+=${miniVersion} \
              RS_EXTRA_VERSION+=${extraVersion} \
            && make
          '';
        };

      };

      packages = forAllSystems (system: {
        inherit (nixpkgsFor.${system}) retroshare;
      });


      defaultPackage =
        forAllSystems (system: self.packages.${system}.retroshare);

    };

}
