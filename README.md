# UniTrack

A macOS student record system for Edith Cowan University, written in Swift with
SwiftUI and SwiftData. Built as the demonstration application for **CSP3341
Programming Languages and Paradigms**.

Students, courses, units and enrolments are stored locally, and the app works
out each student's Weighted Average Mark and Grade Point Average using the
university's published method.

## Requirements

| | |
|---|---|
| macOS | 26.0 or later |
| Xcode | 26.6 |
| Swift | 6.3 (Swift 6 language mode) |
| SDK | macOS 26 |

The interface uses Liquid Glass, which needs the macOS 26 SDK. There is no way
to build it against an older SDK without replacing those surfaces.

## Building and running

```bash
open UniTrack.xcodeproj
```

Then press ⌘R. From the command line:

```bash
xcodebuild -project UniTrack.xcodeproj -scheme UniTrack -configuration Debug build
```

On first launch the app asks you to create an administrator account. Nothing is
seeded with a known password — see *Security* below. Sample students, a course
and its units are created automatically so the screens aren't empty.

## Checking the calculations

```bash
./Verification/run.sh
```

This compiles the real calculator and hashing sources — not a copy — and runs
them against known answers:

- the WAM worked example ECU publishes, which should come out at **58.43**
- password hashing: salts differ per account, correct passwords verify, wrong
  ones don't, and short passwords are rejected

## Architecture

Four layers, with dependencies pointing downwards only.

| Layer | Responsibility |
|---|---|
| Presentation | SwiftUI views. Never touches the store directly. |
| Domain | Session and access rules, WAM/GPA calculation, grade banding, analytics. |
| Persistence | SwiftData `ModelContainer` and `ModelContext`. |
| Model | The `@Model` types that get persisted. |

### Access control

Two roles, and the difference is real rather than cosmetic.

| | General user | Administrator |
|---|---|---|
| Sign in | yes | yes |
| See own record | yes | yes |
| See other students | **no** | yes |
| Edit records | no | yes |
| Manage accounts | no | yes |
| Analytics | own results only | whole cohort |

A general user's account is linked to one student, and `SessionStore` decides
what is visible. Admin-only sections are not built for a general user at all,
rather than shown disabled, and `requireEditPermission()` re-checks the role in
the domain layer so the guarantee doesn't depend on the views being correct.

### Security

- Passwords are never stored. Each account keeps a random 16-byte salt, an
  iteration count, and a PBKDF2-HMAC-SHA256 key.
- 210,000 iterations, which is OWASP's current guidance for PBKDF2-HMAC-SHA256.
  The count is stored per account so it can be raised later without locking
  anyone out.
- Verification compares every byte rather than stopping at the first mismatch,
  so the time it takes doesn't reveal how much of the hash matched.
- There are no credentials anywhere in the source. The first administrator is
  created by whoever runs the app.

## File map

| Path | What's in it |
|---|---|
| `UniTrack/UniTrackApp.swift` | App entry point, SwiftData container, store recovery |
| `UniTrack/Models/` | `Student`, `Course`, `Unit`, `Enrolment`, `UserAccount`, and the `Grade`, `Role`, `EnrolmentStatus` enums |
| `UniTrack/Domain/WAMCalculator.swift` | Weighted Average Mark, per the ECU method |
| `UniTrack/Domain/GPACalculator.swift` | Grade Point Average on the 4- and 7-point scales |
| `UniTrack/Domain/GradeMapper.swift` | Mark to grade band, and a consistency check |
| `UniTrack/Domain/Analytics.swift` | Figures behind the dashboard charts |
| `UniTrack/Domain/SessionStore.swift` | Who is signed in, what they may see and do |
| `UniTrack/Domain/Security/PasswordHasher.swift` | PBKDF2 salting, derivation and verification |
| `UniTrack/Views/MainView.swift` | Sidebar navigation |
| `UniTrack/Views/DashboardView.swift` | Charts and summary figures |
| `UniTrack/Views/StudentsScreen.swift` | Student list and record, scoped by role |
| `UniTrack/Views/StudentDetailView.swift` | One student's record, WAM and GPA |
| `UniTrack/Views/AccountsView.swift` | Administrator account management |
| `UniTrack/Views/SignInView.swift` | Sign in |
| `UniTrack/Views/FirstRunSetupView.swift` | Creating the first administrator |
| `UniTrack/Views/Components/` | Avatar, chip, metric card, section card, logo |
| `UniTrack/Support/SampleData.swift` | Seeds 28 students, a course and its units |
| `UniTrack/Support/Theme.swift` | Accent and chart colours |
| `UniTrack/Support/DemoMode.swift` | Debug-only helper for capturing screenshots |
| `Verification/` | Standalone checks for the calculations and hashing |

## Notes on the data

The course code and unit codes are the real ones ECU publishes for the Bachelor
of Computer Science. Student names, marks and dates are invented. The sample
cohort is generated from a fixed seed, so a fresh install always produces the
same 28 students and the dashboard is comparable between runs.

The academic year runs over three teaching periods, which is how enrolments are
spread across Semesters 1 to 3.

## Assets

The Edith Cowan University logo is used on the sign in and setup screens. It
belongs to the university and is reproduced here for coursework only.

The asset catalogue carries two versions. The supplied artwork has a black
wordmark, which disappears against a dark window, so a light-appearance and a
dark-appearance variant are both stored under
`UniTrack/Assets.xcassets/ECULogo.imageset/` and macOS picks whichever matches.
Only the wordmark was recoloured for the dark version — the teal leaf is
untouched, and the logo itself has not been redrawn.

If the artwork is ever missing, `UniversityLogo` falls back to a system symbol
so the app still builds and runs.
