import React from 'react'

const Hero = () => {
  return (
    <div className="flex flex-col items-center justify-center min-h-screen text-center">
        <a href="/" className="text-white text-2xl font-bold">
            <img src="/VoxNode.png" alt="VoxNode Logo" className="h-10" />
        </a>
        <h1 className="font-semibold text-5xl mt-4">"Kritik Asik Tanpa Harus Terusik"</h1>
        <p className="text-gray-600 mt-2 px-56">
            Deliver your thoughts and criticisms freely without worry. Share your voice, spark meaningful change, and stay protected — all while keeping it smart, safe, and impactful. Use your words, let us protect your space. 
        </p>
        <h3 className="mt-2">#KritikAsikTanpaTerusik</h3>
        <button className="bg-black text-white text-xl px-6 py-2 rounded mt-4">
            Start Your Opinion
        </button>
    </div>

  )
}

export default Hero