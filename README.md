# Sabin.io Powershell Script Analyser rules

Rule| Description
-|-|
[PesterScriptBlocksForV5Compat](src/Rules.psm1) | Looks for script blocks that aren't within a pester block that executes. Pester 5 introduces different phases discovery and run. (v4 only had run) this results in odd behaviours if you don't include your code in BeforeAll, BeforeEach or BeforeDiscovery

