{
  proton-cachyos-slr-bin,
  steamDisplayName ? "Proton CachyOS slr v3",
}:
proton-cachyos-slr-bin.override {
  microarch = "x86_64_v3";
  inherit steamDisplayName;
}
