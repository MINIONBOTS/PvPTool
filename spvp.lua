local spvp = {} -- important to define this as local, else other users can access and steal your code!
spvp.modulefunctions = GetPrivateModuleFunctions()
spvp.btreecontext = {}
spvp.gateswhereclosed = false

-- Settings.GW2Minion.combatmovement
-- Required for private addons with additional private sub-behavior trees
function spvp.LoadSubtreeData(filename)
	if ( FileExists(GetLuaModsPath()  .. "\\PvPtool\\data\\"..filename)) then 
		return FileLoad(GetLuaModsPath()  .. "\\PvPtool\\data\\"..filename)
			
	else
		
		local files = spvp.modulefunctions.GetModuleFiles()
		if(table.valid(files)) then
			for _,filedata in pairs(files) do
				if( btreeinfo.filename == filedata.f) then
					local fileString = spvp.modulefunctions.ReadModuleFile(filedata)
					if(fileString) then
						local fileFunction, errorMessage = loadstring(fileString)
						if (fileFunction) then
							return fileFunction()
						end
					end
					break
				end
			end
		end
	end
end

-- Gets called by the BT-Manager, after changes on the BT were saved. We need to update our currently running instance of our BT in that case.
function spvp.ReloadBTree()
	
	-- The required information table to add an "external BTree"
	local btreeinfo = {
			filename = "sPvP.bt",
			filepath = GetLuaModsPath()  .. "\\\PvPtool\\data",
			
			LoadContext = function() return spvp.GetContext() end,	-- Is called when the BTree is started. Allows us to supply a custom context table to the BTree
			Reload = function() spvp.LoadBehaviorFiles() end,				-- Called when the BTree was changed and saved in the BT-Editor. Reload all addon bt files here.
			private = spvp.modulefunctions ~= nil,																	-- if set, it will be treated as a private addon, loadable from a .paf file.
			LoadSubTree = function(filename) return spvp.LoadSubtreeData(filename) end,	-- Required for private addons with additional private sub-behavior trees
		}
	
	if ( FileExists(GetLuaModsPath()  .. "\\\PvPtool\\\data\\\sPvP.bt")) then 
		-- The Developer case, he has the local BTree files.
		d("[sPvP] - Loading Developer Version")	
		spvp.btree = BehaviorManager:LoadBehavior( btreeinfo )					-- Loads the BTree data from the locally present .bt file
			
	else
		-- The User case, he has only the compiled .paf file.
		d("[sPvP] - Loading PvPtool Addon")
		
		-- We need to load the BTree data by ourself from our local .paf and pass that to the LoadBehavior() to create an instance of it.
		local files = spvp.modulefunctions.GetModuleFiles("data")		
		if(table.valid(files)) then
			for _,filedata in pairs(files) do
				if( btreeinfo.filename == filedata.f) then
					local fileString = spvp.modulefunctions.ReadModuleFile(filedata)
					if(fileString) then						
						local fileFunction, errorMessage = loadstring(fileString)
						if (fileFunction) then
							btreeinfo.data = fileFunction()					
						end
					end
					break
				end
			end
		end
		
		if (table.valid(btreeinfo.data)) then
			spvp.btree = BehaviorManager:LoadBehavior( btreeinfo )
		end
	end
	
	
	if ( not table.valid(spvp.btree)) then
		ml_error("[sPvP] - Failed to load PvPtool behaviortree")
	end
end

-- The BT Manager will call this, to refresh it's internal list of avalable BotModes and Sub-BehaviorTree files
-- ALL .bt AND .st files need to get added !
function spvp.LoadBehaviorFiles()
	--[[ Add Subtree files
	local btreeinfo = {
			filename = "subee.st",
			filepath = GetLuaModsPath()  .. "\\\PvPtool",
			private = true,																	-- if set, it will be treated as a private addon, loadable from a .paf file.
			LoadSubTree = function(filename) return spvp.LoadSubtreeData(filename) end,	-- Required for private addons with additional private sub-behavior trees	
	}
	BehaviorManager:LoadSubBehavior( btreeinfo )
	]]
	-- Initialize our main Behavior Tree and add it to the Main Menu
	spvp.ReloadBTree()
end
RegisterEventHandler("RefreshBehaviorFiles", spvp.LoadBehaviorFiles)

-- Add helper Functions to the BTree context, so we can call these functions from inside any BTree Node
spvp.btreecontext.PvPDisableCombatMoveIfCloseToCapturepoint = function(capturePoint)

   if capturePoint ~= nil then
      if (capturePoint.meshpos.distance < 600) then
         if (Settings.GW2Minion.combatmovement) then
            d("Disabling combatmovement")
            Settings.GW2Minion.combatmovement = false
         end
      else
         if (Settings.GW2Minion.combatmovement == false) then
            d("Enabling combatmovement")
            Settings.GW2Minion.combatmovement = true
         end
      end
   end
end

-- Add helper Functions to the BTree context, so we can call these functions from inside any BTree Node
spvp.btreecontext.PvPStartGatesOpen = function()
	-- Get the closest Gate to the gate position by map and check it's state if it is open
	local gatelist = GadgetList("contentid=17513")
	if ( table.valid(gatelist) ) then		
		local currentmapid = Player.localmapid or 0
		local id, gate = next(gatelist)
		while ( id and gate ) do
			if(( gate.type == 5 and gate.status == 464399) or (gate.type == 17 )) then

				-- TODO: ADD ALL OTHER POSITIONS NEAR THE GATES OF EACH MAP HERE	
				-- Battle of Champions
				if ( currentmapid == 1011 ) then	
					if ( math.distance3d(gate.pos, { x= -5057.98, y= 3812.58, z= -912.76 }) < 100 ) then return true end 	-- Blue Team
										
				-- Forest of Nifhel
				elseif( currentmapid == 554 ) then
					if ( math.distance3d(gate.pos, { x= 2463.81, y= -426.95, z= -845.65 }) < 100 ) then return true end 	-- Red Team
					if ( math.distance3d(gate.pos, { x= -2863.18, y= -436.46, z= -853.12 }) < 100 ) then return true end 	-- Blue Team
					
				-- Skyhammer
				elseif( currentmapid == 900 ) then
					if ( math.distance3d(gate.pos, { x= -1394.88, y= 4965.36, z= -3141.97 }) < 100 ) then return true end 	-- Red Team
					if ( math.distance3d(gate.pos, { x= -1382.77, y= -1630.64, z= -3141.97 }) < 100 ) then return true end 	-- Blue Team
					
            -- Tempel of the Silent
				elseif( currentmapid == 875 ) then
					if ( math.distance3d(gate.pos, { x= 2463.60, y= -789.67, z= -3782.63 }) < 100 ) then return true end 	-- Red Team
					if ( math.distance3d(gate.pos, { x= -6698.29, y= 139.00, z= -3748.56 }) < 100 ) then return true end 	-- Blue Team
					
				-- Vermächtnis des Feindfeuers
				elseif( currentmapid == 795 ) then
					if ( math.distance3d(gate.pos, { x= -1990.01, y= -2303.84, z= -934.43 }) < 100 ) then return true end 	-- Red Team
					if ( math.distance3d(gate.pos, { x= 7969.79, y= 5774.64, z= -1222.82 }) < 100 ) then return true end 	-- Blue Team	
				
				-- Geisterwacht
				elseif( currentmapid == 894 ) then
					if ( math.distance3d(gate.pos, { x= -512.29, y= -3040.79, z= -575.66 }) < 100 ) then return true end 	-- Red Team
					if ( math.distance3d(gate.pos, { x= 2328.14, y= -3184.49, z= -570.14 }) < 100 ) then return true end 	-- Blue Team	
				
				-- Die Schlacht von Kyhlo
				elseif( currentmapid == 549 ) then
					if ( math.distance3d(gate.pos, { x= -3433.52, y= 2744.00, z= -513.18 }) < 100 ) then return true end 	-- Red Team
					if ( math.distance3d(gate.pos, { x= 3027.34, y= -3805.32, z= -510.92 }) < 100 ) then return true end 	-- Blue Team

				-- Ewiges Kolosseum
				elseif( currentmapid == 1171 ) then
					if ( math.distance3d(gate.pos, { x= 5145.99, y= -2484.39, z= -500.07 }) < 100 ) then return true end 	-- Red Team
					if ( math.distance3d(gate.pos, { x= -5300.51, y= 2493.84, z= -500.07 }) < 100 ) then return true end 	-- Blue Team
               
            -- Rache des Steinbocks
				elseif( currentmapid == 1163 ) then
					if ( math.distance3d(gate.pos, { x= -4525.19, y= -3155.21, z= -1379.11 }) < 100 ) then return true end 	-- Red Team
					if ( math.distance3d(gate.pos, { x= 4481.84, y= -3111.80, z= -1379.11 }) < 100 ) then return true end 	-- Blue Team
											
				end
			end
			id,gate = next (gatelist,id)
		end
	end  
	
   return false
end

-- Used in Match Start...another way to find out if the match started already.
spvp.btreecontext.PvPFightStarted = function()
	return PvPManager:IsMatchStarted()
end

-- To get the nearest not fully captured Point
spvp.btreecontext.PvPGetBestCapturePoint = function()
   local currentmapid = Player.localmapid or 0
	local nearestcapturepoint
	local glist = GadgetList("type=2")
	if ( table.valid(glist)) then
		local id,gadget = next(glist)
		while (id and gadget) do
			if (spvp.btreecontext.currentteam == "red" and gadget.status == 185730 or
				spvp.btreecontext.currentteam == "blue" and gadget.status == 4274 or
				gadget.status == 3267563698 or
				gadget.status == 207234327 or
				gadget.status == 1482872194 or	-- when the shit switches factions it is shortly this number 
				gadget.status == 5907735) then
            
               if currentmapid == 1163 and math.distance3d(gadget.pos, { x= -12.56, y= 2099.06, z= -298.02 }) < 100 then -- Glocke Rache des Steinbocks
                  -- It is blacklisted - Skip it
               else
                  if ( gadget.meshpos and gadget.meshpos.distance < 999999  and ( not nearestcapturepoint or gadget.distance < nearestcapturepoint.distance)) then
                     nearestcapturepoint = gadget
                  end
               end
			elseif ( gadget.distance < 1000 ) then
				d(gadget.status)
			end
			id,gadget = next(glist,id)
		end
	end
	if ( nearestcapturepoint ) then
		return nearestcapturepoint
	end	
end

spvp.btreecontext.GetBestAggroTarget = function()
	local range = ml_global_information.AttackRange or 750
	
	if ( range < 200 ) then range = 750 end -- extend search range a bit for melee chars
	if ( range > 1000 ) then range = 1000 end -- limit search range a bit for ranged chars
	
	-- Try to get Aggro Enemy Players with los in range first
	local target = gw2_common_functions.GetCharacterTargetExtended("player,onmesh,maxdistance="..tostring(range))
		
	if(table.valid(target) and (not target.attackable or target.pathdistance >= 9999999)) then
		gw2_blacklistmanager.AddBlacklistEntry(GetString("Temporary Combat"), target.id, target.name, 5000)
		d("[GetBestAggroTarget] - Blacklisting "..target.name.." ID: "..tostring(target.id))
		target = nil
	end
	
	if ( target and target.id ) then
		if ( target.distance < 1500 and target.los ) then
			Player:SetTarget(target.id)
		end
		return target
	end
	return nil
end
	
-- Is called when the BTree is started. Allows us to supply a custom context table to the BTree
function spvp.GetContext()
	spvp.btreecontext.PvPFightStarted = spvp.btreecontext.PvPFightStarted
	spvp.btreecontext.PvPGetBestCapturePoint = spvp.btreecontext.PvPGetBestCapturePoint
	spvp.btreecontext.GetBestAggroTarget = spvp.btreecontext.GetBestAggroTarget
   spvp.btreecontext.PvPDisableCombatMoveIfCloseToCapturepoint = spvp.btreecontext.PvPDisableCombatMoveIfCloseToCapturepoint
		
	return spvp.btreecontext
end
