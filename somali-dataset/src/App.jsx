import React from "react";
import { BrowserRouter as Router } from "react-router-dom";
import { CssBaseline } from "@mui/material";
import { AuthProvider } from "./context/AuthContext";
import AppRoutes from "./Routes";

function App() {
  return (
    <Router>
      <CssBaseline />
      <AuthProvider>
        <AppRoutes />
      </AuthProvider>
    </Router>
  );
}

export default App;
