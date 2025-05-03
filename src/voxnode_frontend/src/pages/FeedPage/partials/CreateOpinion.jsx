import React, { useState, useEffect } from "react";
import { useNavigate } from "react-router-dom";
import { initializeVoxnodeActor } from "../../../lib/actor";
import { AuthClient } from "@dfinity/auth-client";
import { Actor } from "@dfinity/agent";

const CreateOpinion = () => {
  const [formData, setFormData] = useState({ content: "" });
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");
  const [actor, setActor] = useState(null);
  const navigate = useNavigate();

  useEffect(() => {
    async function init() {
      try {
        const initializedActor = await initializeVoxnodeActor();
        setActor(initializedActor);
        
        // Verify methods exist
        if (typeof initializedActor.postOpinion !== "function") {
          throw new Error("Actor missing postOpinion method");
        }
      } catch (err) {
        console.error("Actor initialization failed:", err);
        setError("Failed to initialize connection");
      }
    }
    
    init();
  }, []);


  const handleSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);
    setError("");

    try {
      // Validate input
      if (!formData.content.trim()) {
        throw new Error("Opinion content cannot be empty");
      }

      console.log("Calling postOpinion with:", formData.content);
      
      // Call the canister method
      const newOpinionId = await actor.postOpinion(formData.content, [], []);

      console.log("Successfully posted opinion. ID:", newOpinionId);
      
      // Reset form
      setFormData({
        content: "",
      });
      
      // Close modal and redirect
      document.getElementById('create-opinion-modal').checked = false;
      navigate("/"); // or wherever you want to redirect
      
    } catch (err) {
      console.error("Error posting opinion:", err);
      
      let errorMessage = err.message;
      
      // Handle specific error cases
      if (err.message.includes("Not enough points")) {
        errorMessage = "You don't have enough points to post an opinion";
      } else if (err.message.includes("inappropriate content")) {
        errorMessage = "Your content was flagged as inappropriate";
      }
      
      setError(errorMessage);
    } finally {
      setLoading(false);
    }
  };

  const handleChange = (e) => {
    const { name, value } = e.target;
    setFormData((prev) => ({
      ...prev,
      [name]: value,
    }));
  };

  return (
    <section id="create-opinion" className="flex flex-col">
      <label htmlFor="create-opinion-modal" className="btn">
        Create Opinion
      </label>

      <input type="checkbox" id="create-opinion-modal" className="modal-toggle" />
      <div className="modal" role="dialog">
        <div className="modal-box">
          <h3 className="text-lg font-bold">Create new opinion</h3>
          {error && (
            <div className="alert alert-error mb-4">
              <svg xmlns="http://www.w3.org/2000/svg" className="stroke-current shrink-0 h-6 w-6" fill="none" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M10 14l2-2m0 0l2-2m-2 2l-2-2m2 2l2 2m7-2a9 9 0 11-18 0 9 9 0 0118 0z" />
              </svg>
              <span>{error}</span>
            </div>
          )}
          <form onSubmit={handleSubmit}>
            <textarea
              name="content"
              placeholder="What's your opinion?"
              value={formData.content}
              onChange={handleChange}
              className="textarea textarea-bordered w-full mb-4"
              rows={4}
              required
            ></textarea>
            <div className="modal-action">
              <button 
                type="submit" 
                className={`btn btn-primary ${loading ? 'loading' : ''}`}
                disabled={loading}
              >
                {loading ? 'Posting...' : 'Submit'}
              </button>
              <label htmlFor="create-opinion-modal" className="btn">
                Cancel
              </label>
            </div>
          </form>
        </div>
      </div>
    </section>
  );
};

export default CreateOpinion;