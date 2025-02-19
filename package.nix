{ lib
, stdenv_32bit
, pkgsi686Linux
, perlPackages
, elfkickers
, nasm
, upx
, zip
, withTarget ? "vulpforth"
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
    make ${if withTarget == "vulpforth.zip" then "vulpforthzip files.zip CFLAGS=-O1" else withTarget}
  '' + lib.optionalString withSstrip ''
    ${elfkickers}/bin/sstrip -z ${if withTarget == "vulpforth.zip" then "vulpforthzip" else withTarget}
  '' + lib.optionalString (withTarget == "vulpforth.zip") ''
    ${perlPackages.strip-nondeterminism}/bin/strip-nondeterminism files.zip
    ${lib.optionalString withUpx "${upx}/bin/upx --best vulpforthzip"}
    ${lib.optionalString withSstrip "${elfkickers}/bin/sstrip -z vulpforthzip"}
    make vulpforth.zip
  '';

  installPhase = ''
    install -Dt $out/bin ${withTarget}
  '';
}
