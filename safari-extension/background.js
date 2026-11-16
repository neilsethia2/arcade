/*
 * Safari Arcade background script.
 *
 * Its only job: when the toolbar icon is clicked, show the arcade.
 * The arcade opens in a full browser tab rather than a popup, because a
 * popup is far too small for the games and closes whenever it loses focus.
 *
 * This file is plain JavaScript on purpose. Safari loads it directly, so it
 * skips the React build and stays easy to read and debug.
 */

const api = globalThis.browser ?? globalThis.chrome;

const ARCADE_PAGE = "index.html";
const FOCUS_MESSAGE = "arcade:focus";
const REPLY_TIMEOUT_MS = 400;

/**
 * Asks any arcade tab that is already open to bring itself to the front.
 * Resolves to true if one answered. Asking the page (instead of searching
 * through tabs here) means the extension needs no permission to read the
 * user's tabs.
 */
async function focusExistingArcadeTab() {
  const noReply = new Promise((resolve) => setTimeout(() => resolve(undefined), REPLY_TIMEOUT_MS));
  try {
    const reply = await Promise.race([api.runtime.sendMessage({ type: FOCUS_MESSAGE }), noReply]);
    return Boolean(reply && reply.ok);
  } catch {
    // No arcade page is open to receive the message. That is the normal case.
    return false;
  }
}

async function openArcade() {
  if (await focusExistingArcadeTab()) return;
  await api.tabs.create({ url: api.runtime.getURL(ARCADE_PAGE) });
}

api.action.onClicked.addListener(() => {
  openArcade().catch((error) => {
    console.error("Safari Arcade: could not open the arcade tab", error);
  });
});
