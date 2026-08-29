# Quick placement guide

## Fastest manual setup

1. In `ReplicatedStorage`, create a Folder named `FarmRNG`.
2. Inside it, create Folders named `Config` and `Shared`.
3. Add the ModuleScripts from `ReplicatedStorage/FarmRNG/...`.
4. In `ServerScriptService`, create a Folder named `FarmRNG`.
5. Inside it, create a Folder named `Services`.
6. Add all service ModuleScripts.
7. Add `Bootstrap.server.lua` as a normal Script under `ServerScriptService/FarmRNG` and name it `Bootstrap`.
8. Add `FarmRNGClient.client.lua` as a LocalScript under `StarterPlayer > StarterPlayerScripts` and name it `FarmRNGClient`.
9. Press Play.

## Testing notes

The UI is intentionally ugly and temporary. It is only for testing server logic.

The game currently has no real map, physical crates, trucks, or Super Mart claim zone yet. Those are the next coding pass.
