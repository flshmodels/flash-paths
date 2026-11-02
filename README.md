# Flash Paths

Generate an explicit object-lookup module for a Studio selection. Names are quoted safely and duplicate sibling names are refused. No script source is read, inserted or executed by the plugin.

## Install

1. Download/extract the repository. No runtime packages are required.
2. In a separate Studio test place, use Explorer's **Insert from File** to insert `FlashPaths.rbxmx`.
3. Select its root Script (three child ModuleScripts) and choose **Save as Local Plugin**.
4. Remove the imported root from the place. Open **Flash Paths → Paths** on the Plugins toolbar.

The plugin refuses its work during play tests. The dock panel follows Studio's theme.

## Use it

Select up to 50 objects and click **Generate lookup module**. Copy the generated text into your own ModuleScript. It returns a function; call that function to receive an array of references in the numbered selection snapshot order.

```lua
local resolve = require(path.to.YourLookupModule)
local references = resolve()
local firstObject = references[1]
```

Immediate mode checks existing children. Wait mode uses WaitForChild with a 10-second timeout **per child hop**, then checks uniqueness. This is not a single overall timeout; a deep path can wait much longer. Both modes report missing or ambiguous names. Sibling checks also run when the generated module resolves objects, since the hierarchy may change later.

The generator uses the actual ancestor chain and GetService class names, not a split of GetFullName. Dots, spaces, quotes, newlines and Unicode in names remain literal. Fixed-width UTF-8 byte escapes avoid injecting names into Luau code. Names must be valid UTF-8 and at most 4096 bytes.

Limits: 50 selected objects, 64 child hops per path, 10000 children per inspected parent, 100000 distinct sibling entries inspected during generation, and 64 KiB of generated source. Detached objects and top-level non-services are refused. Selection duplicates are omitted; services themselves are allowed.

Choose the correct client/server context. A client cannot resolve ServerStorage contents, and streaming or runtime changes can leave a path unavailable. The generated code checks name uniqueness at lookup time, not object identity forever. It is not a security boundary or a replacement for explicit game architecture. See [Instance lookup behavior](https://create.roblox.com/docs/reference/engine/classes/Instance).

`Adapter.generate(selection, waitForChildren)` captures service/name records and returns `{records, source}`. `Rules.quote(text)` encodes names; `Rules.generate(records, waitForChildren)` produces the module. The dock panel is a copyable output view with no Apply button or undo recording.

## Development and checks

Source is in `src`. Rebuild with Python 3.11+; run logic checks with Lune 0.11.1:

```sh
python build.py
python -m unittest discover -s tests -v
lune run tests/run
```

CI compiles every source file, tests rules/adapters with fake Studio objects, checks the packaged source and rebuilds it for comparison. Lune is installed on GitHub's runner, not your PC. Common UI/scope/recording helpers are copied into individual Flash repos so they install independently.

**Local-plugin installation, dock behavior and native Studio undo have not been verified live.** The path generator has no undo recording. See [Studio checks](docs/STUDIO-CHECKS.md). Automated checks do not establish live game integration.

MIT licensed. See [LICENSE](LICENSE).
