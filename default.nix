#!/usr/bin/env nix-build

{ pkgs ? import <nixpkgs> {} }:
let generator = pkgs.stdenv.mkDerivation {
      name = "luketebbscom-generator";
      src = ./generator;
      phases = "unpackPhase buildPhase";
      buildInputs = [
        pkgs.sass (pkgs.haskellPackages.ghcWithPackages (p: with p; [ hakyll ]))
      ];
      buildPhase = ''
        mkdir -p $out/bin
        ghc -O2 -dynamic --make Main.hs -o $out/bin/generate-site
      '';
    };
in pkgs.stdenv.mkDerivation {
     name = "luketebbscom-site";
     src = ./site;
     phases = "unpackPhase buildPhase";
     buildInputs = [ pkgs.sass generator (pkgs.haskellPackages.ghcWithPackages (p: with p; [ hakyll ])) ];
     buildPhase = ''
       export LOCALE_ARCHIVE="${pkgs.glibcLocales}/lib/locale/locale-archive";
       LANG=en_US.UTF-8 generate-site build
       mkdir $out
       cp -r _site/* $out
     '';
     shellHook = ''
       export PS1="\n\[\033[1;32m\][\[\033[1;34m\]$name\[\033[1;32m\]:\w]$\[\033[0m\] "
     '';
     
   }
