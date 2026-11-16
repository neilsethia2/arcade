import { SystemCheck } from "./pages/SystemCheck";

/**
 * Milestone 1 shell. It proves the app can show its interface and that
 * saved data survives. The home screen with the six game cards
 * replaces the system check in Milestone 2.
 */
export function App() {
  return (
    <div className="shell">
      <header className="shell__header">
        <h1 className="shell__title">Safari Arcade</h1>
        <p className="shell__tagline">Your personal gaming corner.</p>
      </header>
      <main className="shell__main">
        <SystemCheck />
      </main>
      <footer className="shell__footer">Version {__APP_VERSION__}</footer>
    </div>
  );
}
