// utils/actor.js
import { Actor, HttpAgent } from "@dfinity/agent";
import { idlFactory } from "declarations/voxnode_backend";

export async function initializeVoxnodeActor() {
  // Check if we're in development and use local replica
  const isDevelopment = process.env.NODE_ENV !== "production";
  const host = isDevelopment ? "http://localhost:8000" : "https://ic0.app";

  // Create auth client
  const authClient = await AuthClient.create();
  const identity = authClient.getIdentity();

  // Create HTTP agent
  const agent = new HttpAgent({ 
    host,
    identity 
  });

  // Fetch root key for local development
  if (isDevelopment) {
    await agent.fetchRootKey();
  }

  // Create actor
  const actor = Actor.createActor(idlFactory, {
    agent,
    canisterId: process.env.VOXNODE_CANISTER_ID,
  });

  return actor;
}