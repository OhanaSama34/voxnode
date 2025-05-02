import { useState } from 'react';
import { voxnode_backend } from 'declarations/voxnode_backend';
import './styles/tailwind.css';
import Navbar from './components/Navbar';
import Hero from './components/Hero';
import Content from './components/Content';


function App() {
  const [greeting, setGreeting] = useState('');

  function handleSubmit(event) {
    event.preventDefault();
    const name = event.target.elements.name.value;
    voxnode_backend.greet(name).then((greeting) => {
      setGreeting(greeting);
    });
    return false;
  }

  return (
    <main>
      <Navbar/>
      <Hero/>
      <Content/>
    </main>
  );
}

export default App;
