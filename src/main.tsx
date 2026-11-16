import { StrictMode } from "react";
import { createRoot } from "react-dom/client";
import { App } from "./App";
import { runDiagnostics } from "./services/diagnostics";
import { listenForFocusRequests } from "./services/extension";
import "./styles/tokens.css";
import "./styles/global.css";

const container = document.getElementById("root");
if (!container) {
  throw new Error("Safari Arcade could not start: index.html is missing the #root element.");
}

listenForFocusRequests();

// Starts the save test straight away, independently of what is on screen.
void runDiagnostics();

createRoot(container).render(
  <StrictMode>
    <App />
  </StrictMode>,
);
