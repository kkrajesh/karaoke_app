
import React from 'react';
import { Role } from '../types';
import { CrownIcon, MicIcon, UsersIcon } from '../constants';

interface RoleSelectorProps {
  onSelectRole: (role: Role) => void;
}

const RoleCard: React.FC<{
    icon: React.ReactNode;
    title: string;
    description: string;
    onClick: () => void;
}> = ({ icon, title, description, onClick }) => (
    <div
        onClick={onClick}
        className="bg-gray-800 rounded-lg p-6 text-center border-2 border-transparent hover:border-purple-500 hover:bg-gray-700 transition-all duration-300 cursor-pointer transform hover:scale-105"
    >
        <div className="flex justify-center items-center mb-4 text-purple-400">
            {icon}
        </div>
        <h3 className="text-2xl font-bold text-white mb-2">{title}</h3>
        <p className="text-gray-400">{description}</p>
    </div>
);


const RoleSelector: React.FC<RoleSelectorProps> = ({ onSelectRole }) => {
  return (
    <div className="flex flex-col items-center justify-center">
      <h2 className="text-3xl font-bold mb-8 text-center">Join the Party! Who are you?</h2>
      <div className="grid grid-cols-1 md:grid-cols-3 gap-8 w-full max-w-4xl">
        <RoleCard 
            icon={<CrownIcon className="w-12 h-12" />}
            title="I'm the Host"
            description="Manage the queue, control the music, and run the show."
            onClick={() => onSelectRole(Role.HOST)}
        />
        <RoleCard 
            icon={<MicIcon className="w-12 h-12" />}
            title="I'm a Singer"
            description="Browse the song library, pick your anthem, and sign up to perform."
            onClick={() => onSelectRole(Role.SINGER)}
        />
        <RoleCard 
            icon={<UsersIcon className="w-12 h-12" />}
            title="I'm in the Audience"
            description="Watch performances, send reactions, and request songs for others."
            onClick={() => onSelectRole(Role.AUDIENCE)}
        />
      </div>
    </div>
  );
};

export default RoleSelector;
