{ pkgs ? import <nixpkgs> {} }:

let

  makeScript = name: runtimeInputs: pkgs.writeShellApplication {
    inherit name;
    runtimeInputs = runtimeInputs;
    text = builtins.readFile ./scripts/${name}.sh;
  };

in

pkgs.symlinkJoin {
  name = "home-utilities";
  paths = [
    (makeScript "bt-last-device" [ pkgs.blueman ])
    (makeScript "bt-disconnect-last" [ pkgs.blueman ])

    (makeScript "clipscreenshot" [ pkgs.grim pkgs.slurp ])
    (makeScript "savescreenshot" [ pkgs.grim pkgs.slurp ])
    (makeScript "screenshot" [ pkgs.grim pkgs.slurp ])

    (makeScript "startwm" [ pkgs.dwm pkgs.dwmb ])

    (makeScript "status" [ ]) # ?
    (makeScript "media-control" [ ])  # ?
    
    (makeScript "lock" [ ]) # ?
    (makeScript "locksuspend" [ ]) # ?
  ];

}
