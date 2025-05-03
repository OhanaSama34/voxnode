import React, { useEffect, useState } from "react";
import MainLayout from "../../layouts/main-layout";
import { voxnode_backend } from "declarations/voxnode_backend";
import { Actor } from '@dfinity/agent';
import CreateOpinion from './partials/CreateOpinion';

const FeedPage = ({ actor }) => {
  const [opinions, setOpinions] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    const fetchOpinions = async () => {
      if (!actor) {
        setError("Wallet not connected");
        setLoading(false);
        return;
      }

      try {
        const metadataArray = await actor.getAllOpinions();
        const parsedOpinion = metadataArray.map(parseMetadata);
        setOpinions(parsedOpinion);
        setLoading(false);
      } catch (err) {
        console.error("Error fetching Opinions:", err);
        setError(err.message);
        setLoading(false);
      }
    };

    fetchOpinions();
  }, [actor]);
  return (
    <>
      <CreateOpinion actor={actor} />
      <section id="feed-content" className="flex flex-col">
        {opinions.length === 0 ? (
          <p className="text-center text-gray-500 py-8">
            No opinions to display.
          </p>
        ) : (
          opinions.map((op) => (
            <div
              key={op.id.toString()}
              className="flex justify-center p-4 border-b border-gray-200"
            >
              <h2 className="text-lg font-bold">{op.id.toString()}</h2>
              <p className="text-gray-600">
                {op.content /* or your real content field */}
              </p>
            </div>
          ))
        )}
      </section>
    </>
  );
};

export default FeedPage;
