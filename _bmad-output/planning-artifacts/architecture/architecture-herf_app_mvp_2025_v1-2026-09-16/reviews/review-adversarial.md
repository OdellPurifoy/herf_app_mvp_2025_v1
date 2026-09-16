# Reviewer Gate — Adversarial Incompatibility Lens

**Verdict:** PASS WITH CONCERNS — the ADs stop the worst legacy patterns but left several letter-compliant collision paths open.

## Critical

- AD-1 named no single creation entrypoint per entity. `MembershipsController#create` fires a welcome mailer; `AdminDashboardController#member_upload` creates `Membership` rows directly with no mailer — both AD-1-compliant, yet comms silently differ by creation path. **Fixed**: AD-1 now requires exactly one designated creation/mutation service per side-effect-bearing entity; alternate creators must call it.

## High

- AD-2 didn't say whether `PlanLimitPolicy` self-computes counts, how it distinguishes total-cap (Membership) vs monthly-cap (Event/SpecialOffer) semantics, or which layer invokes it — leaving a bulk/`save(validate:false)` path able to bypass it. **Fixed**: AD-2 now specifies the policy owns count computation, declares a period-type per resource, and is invoked from exactly one layer (model validation).
- AD-3 stated the invariant with no DB/model enforcement or canonical accessor, risking a race between two independently-built creation paths. **Fixed**: AD-3 now names `lounge_owner.lounge` as the canonical accessor and requires a DB unique constraint.
- AD-8 bound only "comms sent to members," letting an owner-facing alert reintroduce synchronous sends while staying letter-compliant. **Fixed**: broadened to all outbound email/SMS regardless of recipient.

## Medium/Low

- AD-7 banned subscription-status columns but not derived shadow-authority fields (e.g. `grace_period_ends_at`). **Fixed**: wording broadened.
- AD-4 had no contract for policies spanning both AD-5 identity types. **Fixed**: policies now scoped to exactly one identity type.
- Dependency diagram omitted a Jobs→Models edge. **Fixed**: edge added.
- AD-6 had no shared token-issuance convention. **Fixed**: added a Consistency Conventions row pointing at `Rsvp#rsvp_token`'s shape.
- AD-5 doesn't govern a hypothetical future third identity type (staff/sub-accounts). **Not fixed** — no such feature exists or is planned; speculative, doesn't pass the "real trade-off" test for inclusion now. Left out of Deferred too, since it isn't a known gap being intentionally pushed down — revisit only if/when such an identity type is actually proposed.

Applied at Finalize by the parent skill run; see ARCHITECTURE-SPINE.md AD-1 through AD-8, the dependency diagram, and Consistency Conventions.
