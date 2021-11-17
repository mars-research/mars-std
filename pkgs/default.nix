final: prev: {
  mars-research = {
    mars-tools = final.callPackage ./mars-tools { };
    cloudlab-ubuntu-customize = final.callPackage ./cloudlab-ubuntu-customize { };
    mkReproduceHook = final.callPackage ./reproduce-hook { };
  };
}
