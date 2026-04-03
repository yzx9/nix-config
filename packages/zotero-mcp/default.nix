{
  lib,
  fetchFromGitHub,
  python3Packages,
  versionCheckHook,
  stdenv,
}:

python3Packages.buildPythonApplication (finalAttrs: {
  pname = "zotero-mcp";
  version = "0.1.4";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "54yyyu";
    repo = "zotero-mcp";
    tag = "v${finalAttrs.version}";
    hash = "sha256-I5HsioNZRJpEEPb6yeD75JUPkI26D5enybyt/ZMQqh0=";
  };

  build-system = with python3Packages; [
    hatchling
  ];

  dependencies = with python3Packages; [
    chromadb
    ebooklib
    fastmcp
    google-genai
    markitdown
    mcp
    openai
    pydantic
    pymupdf
    python-dotenv
    pyzotero
    requests
    sentence-transformers
    tiktoken
  ];

  nativeCheckInputs = with python3Packages; [
    pytestCheckHook
  ];

  nativeInstallCheckInputs = [
    versionCheckHook
  ];
  doInstallCheck = true;
  versionCheckProgram = "${placeholder "out"}/bin/${finalAttrs.meta.mainProgram}";
  versionCheckProgramArg = "version";
  __darwinAllowLocalNetworking = true;

  # Upstream's server tests still call decorated FastMCP tools as plain
  # functions, but current fastmcp exposes them as FunctionTool objects.
  disabledTests = [
    "test_advanced_search_filters_items"
    "test_advanced_search_rejects_unknown_operation"
    "test_create_note_includes_title_heading"
    "test_search_notes_filters_annotation_blocks"
    "test_batch_update_tags_validates_json_array"
  ];

  pythonImportsCheck = [ "zotero_mcp" ];

  meta = {
    description = "Model Context Protocol server for Zotero";
    homepage = "https://github.com/54yyyu/zotero-mcp";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [
      yzx9
    ];
    platforms = with lib.platforms; linux ++ darwin;
    # Error: terminate called after throwing an instance of 'onnxruntime::OnnxRuntimeException'
    broken = with stdenv.hostPlatform; (isLinux && isAarch64) || (isDarwin && isx86_64);
    mainProgram = "zotero-mcp";
  };
})
