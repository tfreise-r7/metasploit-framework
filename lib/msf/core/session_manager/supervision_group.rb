class Msf::SessionManager::SupervisionGroup < Celluloid::SupervisionGroup
  supervise Msf::SessionManager::ID, as: :msf_session_manager_id
end