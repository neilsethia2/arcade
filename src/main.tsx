import { StrictMode } from "react";
import { createRoot } from "react-dom/client";
import { App } from "./App";
import { listenForFocusRequests } from "./services/extension";
import "./styles/tokens.css";
import "./styles/global.css";

const container = document.getElementById("root");
if (!container) {
  throw new Error("Safari Arcade could not start: index.html is missing the #root element.");
}

listenForFocusRequests();

createRoot(container).render(
  <StrictMode>
    <App />
  </StrictMode>,
);
