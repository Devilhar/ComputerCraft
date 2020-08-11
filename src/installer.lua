-- Use these command to download this installer
-- file = fs.open("installer", "w"); file.write(http.get("https://raw.githubusercontent.com/Devilhar/ComputerCraft/master/published/installer.lua").readAll()); file.flush(); file.close()

loadstring(http.get("https://raw.githubusercontent.com/Devilhar/ComputerCraft/master/published/installer_implementation.lua").readAll())(...)