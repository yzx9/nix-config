_inputs:

final: prev: {
  python3Packages = prev.python3Packages.overrideScope (
    final': prev': {
      pyzotero = prev'.toPythonModule (prev.python3Packages.callPackage ../packages/pyzotero { });
    }
  );
}
