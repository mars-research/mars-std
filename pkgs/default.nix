self: super: {
  mars-research = {
    mars-tools = super.callPackage ./mars-tools { };
    cloudlab-ubuntu-customize = super.callPackage ./cloudlab-ubuntu-customize { };
    mkReproduceHook = super.callPackage ./reproduce-hook { };
  };
}
