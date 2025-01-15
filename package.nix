{ lib
, stdenv_32bit
, pkgsi686Linux
, elfkickers
, nasm
, upx
, zip
, withTarget ? "vulpforth.bin"
, withSstrip ? true
, withUpx ? true
}:

stdenv_32bit.mkDerivation {
  name = "vulpforth";
  dontStrip = true;

  src = ./.;

  nativeBuildInputs = [ nasm zip ];
  buildInputs = with pkgsi686Linux; [ musl ];

  buildPhase = ''
    make ${if withTarget == "vulpforth.zip" then "vulpforthzip CFLAGS=-O1" else withTarget}
  '' + lib.optionalString (withTarget == "vulpforth.zip") ''
    ${lib.optionalString withSstrip "${elfkickers}/bin/sstrip -z vulpforthzip"}
    ${lib.optionalString withUpx "${upx}/bin/upx --best vulpforthzip"}
    make vulpforth.zip
  '';

  installPhase = ''
    install -Dt $out/bin ${withTarget}
  '';
}
