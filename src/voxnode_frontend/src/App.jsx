import React, { useEffect } from "react";
import { useState } from "react";
import { voxnode_backend } from "declarations/voxnode_backend";
import { AuthClient } from "@dfinity/auth-client";
import { createActor } from "declarations/voxnode_backend";
import { canisterId } from "declarations/voxnode_backend/index.js";
import { HttpAgent } from "@dfinity/agent";
import "./styles/tailwind.css";
import Hero from "./components/Hero";
import Content from "./components/Content";
import { Routes, Route, useNavigate } from "react-router";
import { LandingPage } from "./pages/LandingPage/index";
import FeedPage from "./pages/FeedPage/index";
import MainLayout from "./layouts/main-layout";
// import {Alert} from "@/components/ui/alert";

const shortenPrincipal = (principalId) => {
  if (!principalId) return "";

  const parts = principalId.split("-");
  if (parts.length < 5) return principalId; // If not standard format

  return `${parts[0]}-${parts[1]}...${parts[parts.length - 2]}-${
    parts[parts.length - 1]
  }`;
};

const network = process.env.DFX_NETWORK;
const identityProvider =
  // network === "https://identity.ic0.app"
  network === "local"
    ? "https://identity.ic0.app" // Mainnet
    : "http://rdu6s2n-gx777-77774-qaaba-cai.localhost:8080"; // Local

function App() {
  const [alerts, setAlerts] = useState([]);
  const [state, setState] = useState({
    actor: undefined,
    authClient: undefined,
    isAuthenticated: false,
    principal: 'Click "Whoami" to see your principal ID',
  });

  const [greeting, setGreeting] = useState("");

  function handleSubmit(event) {
    event.preventDefault();
    const name = event.target.elements.name.value;
    voxnode_backend.greet(name).then((greeting) => {
      setGreeting(greeting);
    });
    return false;
  }

  return (
    <MainLayout>
      <Navbar
        alerts={alerts}
        setAlerts={setAlerts}
        state={state}
        setState={setState}
      />
      <main>
        <Routes>
          <Route index element={<LandingPage />} />
          <Route path="feeds" actor={state.actor} element={<FeedPage />} />
        </Routes>
      </main>
    </MainLayout>
  );
}

const Navbar = ({ alerts, setAlerts, state, setState }) => {
  // const [alerts, setAlerts] = useState([]);

  // const [state, setState] = useState({
  //   actor: undefined,
  //   authClient: undefined,
  //   isAuthenticated: false,
  //   principal: 'Click "Whoami" to see your principal ID',
  // });
  const [principal, setPrincipal] = useState("");

  const navigate = useNavigate();

  const addAlert = (type, message) => {
    const id = Date.now();
    setAlerts((prev) => [...prev, { id, type, message }]);
  };

  const removeAlert = (id) => {
    setAlerts((prev) => prev.filter((alert) => alert.id !== id));
  };

  // Initialize auth client
  useEffect(() => {
    updateActor();
  }, []);

  const updateActor = async () => {
    try {
      const authClient = await AuthClient.create();
      const identity = authClient.getIdentity();
      setPrincipal(authClient.getIdentity().getPrincipal().toString());

      const host =
        process.env.DFX_NETWORK === "ic"
          ? "https://ic0.app"
          : "http://localhost:8080";

      // Buat agent dengan host yang eksplisit
      const agent = new HttpAgent({
        identity,
        host,
      });

      // Fetch root key di environment lokal
      if (process.env.DFX_NETWORK !== "ic") {
        console.log("Fetching root key in App component");
        try {
          await agent.fetchRootKey();
          console.log("Root key fetched successfully in App");
        } catch (error) {
          console.error("Error fetching root key in App:", error);
        }
      }

      // Gunakan canisterId yang hardcoded sebagai fallback
      const backendCanisterId = canisterId || "bkyz2-fmaaa-aaaaa-qaaaq-cai";
      console.log("Using canister ID:", backendCanisterId);

      const actor = createActor(backendCanisterId, {
        agent,
      });

      const isAuthenticated = await authClient.isAuthenticated();
      console.log("Authentication status:", isAuthenticated);

      setState((prev) => ({
        ...prev,
        actor,
        authClient,
        isAuthenticated,
      }));
    } catch (error) {
      console.error("Error in updateActor:", error);
    }
  };

  const login = async () => {
    try {
      await state.authClient.login({
        identityProvider,
        onSuccess: updateActor,
      });
      addAlert("success", "Logged in successfully!");
    } catch (error) {
      addAlert("error", `Login failed: ${error.message}`);
    }
  };

  const logout = async () => {
    await state.authClient.logout();
    updateActor();
    addAlert("success", "Logout successfully!");
    navigate("/");
  };
  return (
    <header className="navbar shadow-sm sticky top-0 bg-white/20 backdrop-blur z-50">
      <div className="navbar-start">
        <a className="btn btn-ghost text-2xl font-bold">
          Land<span className="text-purple-600 -ml-2">Ranger</span>
        </a>
      </div>
      <div className="navbar-end">
        {!state.isAuthenticated ? (
          <button onClick={login} className="btn btn-primary">
            Login with Internet Identity
          </button>
        ) : (
          <div className="flex gap-2 items-center">
            <div className="dropdown dropdown-end">
              <div
                tabIndex={0}
                role="button"
                className="btn btn-ghost font-mono font-bold grid place-items-center"
              >
                id
              </div>
              <ul
                tabIndex={0}
                className="menu menu-sm dropdown-content bg-base-100 rounded-box z-1 mt-3 w-52 p-2 shadow"
              >
                <li
                  className="py-4 tooltip md:tooltip-left"
                  data-tip={principal}
                >
                  {shortenPrincipal(principal)}
                </li>
                <li>
                  <button onClick={logout} className="btn btn-primary">
                    Logout
                  </button>
                </li>
              </ul>
            </div>
          </div>
        )}
      </div>
    </header>
  );
};

export default App;
