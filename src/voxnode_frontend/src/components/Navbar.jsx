import React from 'react';

const Navbar = () => {
    return (
        <nav className="p-4">
          <div className="max-w-7xl mx-auto flex justify-between items-center">
            <div className="flex flex-row">
              {/* Logo */}
              <a href="/" className="text-white text-2xl font-bold">
                <img src="/VoxNode.png" alt="VoxNode Logo" className="h-10" />
              </a>
    
              {/* Menu */}
              <div className="flex space-x-6">
                {/* Link menu dengan pengecekan aktif */}
                <a
                  href="/education"
                  className={`${
                    location.pathname === '/education' ? 'font-bold text-white' : 'text-gray-400'
                  } hover:text-white transition duration-300`}
                >
                  Education
                </a>
                <a
                  href="/start-opinion"
                  className={`${
                    location.pathname === '/start-opinion' ? 'font-bold text-white' : 'text-gray-400'
                  } hover:text-white transition duration-300`}
                >
                  Start Opinion
                </a>
              </div>
            </div>
    
            {/* Button */}
            <button className="bg-white text-black px-6 py-2 rounded border border-black hover:bg-gray-200 transition duration-300">
              Login With ICP
            </button>
          </div>
        </nav>
      );
};

export default Navbar;
