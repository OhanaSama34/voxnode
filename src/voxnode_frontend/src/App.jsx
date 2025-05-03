import { useState } from "react";
import { voxnode_backend } from "declarations/voxnode_backend";
import "./styles/tailwind.css";
import Navbar from "./components/Navbar";
import Hero from "./components/Hero";
import Content from "./components/Content";
import { Routes, Route } from "react-router";
import { LandingPage } from "./pages/LandingPage/index";
import FeedPage from "./pages/FeedPage/index";
import MainLayout from "./layouts/main-layout";

function App() {
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
      <Navbar />
      <main>
        <Routes>
          <Route index element={<LandingPage />} />
          <Route path="feeds" element={<FeedPage />} />
        </Routes>
      </main>
    </MainLayout>
  );
}

export default App;
