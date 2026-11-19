# UI checkpoint before history redesign

Purpose: preserve the current runnable app design before changing the history screen. This is a source checkpoint, not a new UI implementation or release.

Included: current Flutter application/localizations, Android integration, app-bundled data with notices, dependency manifests, and Dart tests. The source includes accumulated brand recognition, maps, tools and English-support work that the current design depends on; it is not a settings-only change.

Excluded: private Maps/signing configuration, physical-card screenshots and image goldens, HTML promotion/design exports that may contain actual travel history, local research/original fare datasets, caches and personal design-tool state. These remain local and are not deleted. Backend/admin deployment and unpublished original data bundles are not part of this app UI checkpoint.

Validation already completed on this app source: full Flutter831 tests passed; flutter analyze has15 existing diagnostics (0 errors,8 warnings,7 infos), no new diagnostics from the latest badge refinement. Those are local verification results, not a claim that all tests can run without excluded local-only fixtures.

No new build, version bump, production deployment or PR merge is performed for this checkpoint. The dependency manifest's current version is preserved unchanged.
