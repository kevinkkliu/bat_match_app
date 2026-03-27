# MVP Acceptance Checklist

This checklist turns the PRD into an executable review path for product, QA, and engineering.

## Prerequisites

- Preview stack runs at `http://localhost:8080`
- API and database are seeded with preview users and games
- Browser review should use the same-origin preview path unless a direct API debug session is explicitly required

## Demo Path

Use the repo root demo script for a reproducible review flow. It reseeds the database, starts the same-origin preview, and keeps host/guest review repeatable without manual setup.

```bash
cd <path_to_your_project>
./scripts/demo-preview.sh host
```

Use guest mode for browse-only review:

```bash
cd <path_to_your_project>
./scripts/demo-preview.sh guest
```

Suggested demo order:

1. Run `./scripts/demo-preview.sh host`
2. Open `http://localhost:8080`
3. Review host management and contact handoff
4. Rerun `./scripts/demo-preview.sh guest`
5. Re-open `http://localhost:8080`
6. Review browse-only behavior without a seeded preview host account

If you forget the flags, run `./scripts/demo-preview.sh --help`.

## Locked MVP Clarifications

### Guest browse policy

- Guests can browse the feed and open game detail without signing in.
- Guests can see public game metadata only.
- Protected actions such as join, create, or request review must redirect to sign-in or clearly show an auth-required state.

### Contact policy

- MVP does not include in-app chat.
- Private contact details are not required for browse access.
- Any contact handoff is limited to authenticated and relevant participants; rejected, withdrawn, or cancelled requests do not unlock contact access.
- If no contact handoff is configured, the UI should say so clearly instead of failing silently.

### Cancel / withdraw policy

- Host cancellation marks the game as cancelled and stops new join activity.
- Player withdraw is allowed only while the request or approval is still active and the game is not cancelled or completed.
- If an approved player withdraws, the reserved spot is returned.
- Cancelled and completed games remain visible in history, but they should not behave like open games.

## Acceptance Checklist

### 1) Guest browse

- Open the browser preview without signing in.
- Confirm the feed loads successfully.
- Confirm guest users can inspect game cards and open a game detail page.
- Confirm guest users can see only public information.
- Confirm a guest-triggered protected action shows an auth-required state instead of silently failing.

### 2) Register / login

- Open the Profile tab.
- Confirm the user can switch between sign in and register.
- Confirm LINE entry routes to the OAuth flow.
- Confirm email or phone login works with valid credentials.
- Confirm register requires at least one of email or phone.
- Confirm successful auth establishes a session that persists across refresh.

### 3) Create game

- Open Create.
- Confirm the host can fill the required fields and submit a new game.
- Confirm validation blocks incomplete or invalid data.
- Confirm a successfully created game appears in the feed and in My Games.

### 4) AUTO join

- Open a game whose approval mode is AUTO.
- Join the game as a signed-in player.
- Confirm the request is accepted immediately.
- Confirm the reserved spot count decreases atomically.
- Confirm the player appears in My Games as joined.

### 5) MANUAL request

- Open a game whose approval mode is MANUAL.
- Request to join as a signed-in player.
- Confirm the request becomes pending.
- Confirm the player does not consume a spot until approval.
- Confirm the request is visible to the host for review.

### 6) Approve / reject

- Open the host request review path.
- Confirm the host can see pending requests.
- Confirm the host can approve a request and the game updates its remaining spots.
- Confirm the host can reject a request and the request leaves the pending state.
- Confirm cancelled or completed games still show the participant list but no longer allow approve/reject actions.
- Confirm non-host users cannot review another host's requests.

### 7) Withdraw

- Open a player's active join request or joined game.
- Confirm the player can withdraw before the game starts.
- Confirm an approved withdrawal returns the spot.
- Confirm withdrawn requests no longer appear as active joins.
- Confirm withdraw is blocked or clearly handled after cancellation/completion.
- Confirm a completed game does not allow a late withdraw from an approved player.

### 8) My Games

- Open My Games as a signed-in player.
- Confirm joined games are shown separately from hosted games.
- Confirm hosted games can be opened for management or request review.
- Confirm cancelled or completed games are represented consistently.

### 9) Preview review path

- Run the seeded demo preview from the repository root with `./scripts/demo-preview.sh host`.
- Use `./scripts/demo-preview.sh guest` for browse-only review.
- Confirm the app is reachable at `http://localhost:8080`.
- Confirm the review path works without hidden local setup steps.
- Confirm seeded preview users can exercise both guest and host flows.
- Confirm the preview stack can be restarted cleanly without manual database recovery.

## Review Notes

- Use the seeded host user for host-side review.
- Use guest mode for browse-only review.
- Use direct sign-in for player and profile review.
- If a scenario depends on test data, record the exact seed or setup used.
