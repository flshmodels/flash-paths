# Studio checks

Status: not yet run live. Record the Studio version, date and results when checking.

1. Install FlashPaths.rbxmx in a separate test place. Test toolbar toggling, light/dark themes and a narrow dock.
2. Try the valid, invalid and oversized inputs described in the README. Rejected operations should leave the place unchanged.
3. Change the selection/options and check that stale output or previews clear. Remove a target and try again.
4. Verify play-mode refusal and plugin unload cleanup.
5. For Flash Interact, preview a small batch, apply it, Undo once and Redo once. Check all three values and the untouched text/Enabled fields. Test stale-parent/value rejection before Apply.
6. For Flash Paths, copy a generated module into a separate test place and resolve the selected objects. Test immediate/wait modes, duplicate sibling names, quoted names, timeouts and the proper client/server context. Confirm the plugin itself never inserts or runs scripts.
