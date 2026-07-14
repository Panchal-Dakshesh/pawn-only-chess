import React from "react";
import { createRoot } from "react-dom/client";
import App from "./components/App";

document.addEventListener("DOMContentLoaded", () => {
  createRoot(document.getElementById("root")).render(<App />);
});
