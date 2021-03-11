-- This version is limited to Guild aliases
-- If you are not in a guild it should do nothing.



local filter_list;

local EventFrame = CreateFrame("Frame")
EventFrame:RegisterEvent("ADDON_LOADED")
EventFrame:SetScript(
  "OnEvent", function(self,event,...) 
    GuildNick.init();
  end
);


GuildNick = {
  nilFrame = {
    GetName = function() return "Global" end
  },
  nickTable = {},
  MISSES_MAX =100,
  misses = {},
  oldest_miss = 0,
  myName = UnitName("player"),
  realmName = GetRealmName(),
  roster_dirty = true,
  addon_loaded = false,
};


GuildNick.frame = CreateFrame("FRAME", "GuildNickFrame");
GuildNick.frame:SetScript("OnEvent", GuildNick.EventDispatcher);
GuildNick.frame:Show();

GuildNick.frame:RegisterEvent("ADDON_ACTION_FORBIDDEN");
GuildNick.frame:RegisterEvent("ADDON_ACTION_BLOCKED");
GuildNick.frame:RegisterEvent("PLAYER_ENTERING_WORLD");
GuildNick.frame:RegisterEvent("PLAYER_LOGIN");
GuildNick.frame:RegisterEvent("GUILD_ROSTER_UPDATE");
GuildNick.frame:RegisterEvent("PLAYER_ENTERING_WORLD");

--[[
GuildNick.frame:RegisterEvent("CHAT_MSG_SYSTEM"); -- for the /who
GuildNick.frame:RegisterEvent("WHO_LIST_UPDATE"); -- for the /who
]]--



function GuildNick.EventDispatcher(frame, event, ...)
-- DEFAULT_CHAT_FRAME:AddMessage(" event: " .. event,  0.5, 1.0, 0.5, 1);
  local handled = false;
  -- my kingdom for a case/switch!
  
  if nil == event then
  --  DEFAULT_CHAT_FRAME:AddMessage("GN: nil event... somehow...",  0.5, 1.0, 0.5, 1);
  end
  
  if "GUILD_ROSTER_UPDATE" == event then
    UpdateLocalNicknames();
    handled = true;
  end
  
  if false == handled then
 --  DEFAULT_CHAT_FRAME:AddMessage(" event: " .. event,  0.5, 1.0, 0.5, 1);
 end
end


local function UpdateLocalNicknames()
 if (nil ~= IsInGuild()) then
  local guildNoteExp="";
  local name, rank, rankIndex, level, class, zone, note, officernote, online, status;
  local classFileName, achievementPoints, achievementRank, isMobile, isSoREligible, standingID;
  local guildNick, matchcount, i;
  local numGuildMembers = GetNumGuildMembers();
  local spacePos, commaPos, namePos;
  local debugcount = 0;

 
  

   
   
   

    if (GuildNick.roster_dirty) then -- only update the nickTable if we need to
  --   DEFAULT_CHAT_FRAME:AddMessage(" - UpdateLocalNicknames: numGuildMembers=" .. numGuildMembers,  0.5, 1.0, 0.5, 1);
      -- populate nickTable with toon names and their matching "main"
      if numGuildMembers > 1 then -- sanity check the size of the guild
        for	i=1, numGuildMembers do -- iterate over the guild members
          note = ""; 
          officernote = "";
          guildNick = "";
          name, rank, rankIndex, level, class, zone, note, officernote, online, status,
          classFileName, achievementPoints, achievementRank, isMobile, isSoREligible, standingID = GetGuildRosterInfo(i);
          note = strtrim(note); -- WoW utility function to trim whitespace

          -- matching rules: (Expand here for other patterns)
          -- first char is =
          if ( 3 < string.len(note)) then -- note must be at least 4 chars long
            if "=" == string.sub(note,1,1) then
              -- simplify the next bit by tacking a space on the end
              note = note .. " ";
              spacePos = strfind(note, " ");
              if spacePos == nil then
               -- guildNick = "nospace";
              else
                guildNick = string.sub(note, 2, spacePos-1);
              end
        
              -- check for comma version?
              --[[
              namePos = spacePos; -- if it's less than commaPos and not nil
              if namePos > 1 then

              end
              ]]--
        
            end -- "equals" style notes
            if ("" ~= guildNick) then -- add it to the table
           --  DEFAULT_CHAT_FRAME:AddMessage("GN: "..name ..": " .. guildNick,  0.5, 1.0, 0.5, 1);

              GuildNick.nickTable[name] = guildNick;
              debugcount = debugcount +1;
            end
          end -- sanity check note length

        end -- for 1 to numGuildMembers
      end -- sanity check number of members in roster
    GuildNick.roster_dirty = false;
    end
  end
   -- display summary:
   if (false) then -- display summary
--   DEFAULT_CHAT_FRAME:AddMessage("UpdateLocalNicknames() number tested:"..numGuildMembers .." # found:" .. debugcount,  0.5, 1.0, 0.5, 1);
  end
end


function GuildNick.GetNickname(visibleName, noColor)
-- Return a nickname string in parenthesis if one should be displayed
-- the optional {noColor} parameter will return the nickname without color codes if present
  local speakerNick="";
  local miss_name = '';
  local miss_time = '';
  local miss_count = 0;
  local known_miss = false;
  local oldest_name = '';
  local now = time();
  local oldest_age = now;
  if (nil ~= IsInGuild()) then  
    -- 1: normalize the nickname to include realm:
    if nil == (string.find(visibleName, "-" )) then
      visibleName = visibleName .. '-' .. GuildNick.realmName;
    end
  
    -- 2: check the misses for a hit and skip everything else
    for miss_name, miss_time in pairs(GuildNick.misses) do
      if miss_name == visibleName then
        known_miss = true;
        break;
      else 
        if miss_time < oldest_age then
          oldest_name = miss_name;
          oldest_age = miss_time;
          oldest_miss =  miss_count;
          miss_count = miss_count + 1;
        end
      end
    end
  
    if false == known_miss then -- wasn't in the cached misses
  
      -- 3: Make sure we have a roster before trying to look people up;
      UpdateLocalNicknames();
    --  DEFAULT_CHAT_FRAME:AddMessage("GetNickname() normalized name:"..visibleName ..  "# of names in table: " .. GuildNick.Count() ,  0.5, 1.0, 0.5, 1);


      -- 4: Attempt to look up the visible name:
      if GuildNick.nickTable[visibleName] then
        if (noColor) then
          speakerNick = GuildNick.nickTable[visibleName];
        else
         speakerNick="|c909090FF(".. GuildNick.nickTable[visibleName] ..")|r ";
        end
  
      else -- this is not a known nickname, and it wasn't in the misses table. So update the misses table
  
        if miss_count > GuildNick.MISSES_MAX then -- we're out of space, to replace the oldest
            tremove(GuildNick.misses, GuildNick.oldest_miss);
        end
        -- just add a new entry to the misses
        GuildNick.misses[visibleName] = now;    
        end
      end -- the test for known miss
	end
	return speakerNick;
end



function GuildNick.init()

  if ( false == GuildNick.addon_loaded ) then -- only need to load once

    ChatFrame_AddMessageEventFilter("CHAT_MSG_CHANNEL", GuildNick_Filter);
    ChatFrame_AddMessageEventFilter("CHAT_MSG_GUILD", GuildNick_Filter);

    ChatFrame_AddMessageEventFilter("CHAT_MSG_RAID", GuildNick_Filter);
    ChatFrame_AddMessageEventFilter("CHAT_MSG_PARTY", GuildNick_Filter);
    -- FRIENDLIST_UPDATE has the "has come online stuff - might not be a chat filter
    

    GuildNick.addon_loaded = true;
 end
 
  -- is whisper it's own channel?
  --DEFAULT_CHAT_FRAME:AddMessage("GuildNick loaded. Type /guildnick to change settings.",  0.5, 1.0, 0.5, 1);
  --	tinsert(UISpecialFrames,'GUILDNICK_PrefsFrame');

end -- init

function GuildNick.d()
  GuildNick.Dump_filters("CHAT_MSG_GUILD");

end


function GuildNick.Dump_filters(filter_name)
  tbl = ChatFrame_GetMessageEventFilters(filter_name);
  print(filter_name);
  
  indent = 0
  local toprint = string.rep(" ", indent) .. "{\r\n"
  indent = indent + 2 
  for k, v in pairs(tbl) do
    toprint = toprint .. string.rep(" ", indent)
    if (type(k) == "number") then
      toprint = toprint .. "[" .. k .. "] = "
    elseif (type(k) == "string") then
      toprint = toprint  .. k ..  "= "   
    end
    if (type(v) == "number") then
      toprint = toprint .. v .. ",\r\n"
    elseif (type(v) == "string") then
      toprint = toprint .. "\"" .. v .. "\",\r\n"
    elseif (type(v) == "table") then
      toprint = toprint .. tprint(v, indent + 2) .. ",\r\n"
    else
      toprint = toprint .. "\"" .. tostring(v) .. "\",\r\n"
    end
  end
  toprint = toprint .. string.rep(" ", indent-2) .. "}"


  print(toprint);
 
end
 
 

function GuildNick_Filter(self, event, msg, author, ...) 
  -- event tells us which channel this convo is happening. i.e. CHAT_MSG_CHANNEL
  if ( "" ~= msq) then -- no need to process if there is no payload
    local nick = GuildNick.GetNickname( author,false); -- let's try no color
    if "" == nick then
   --   msg =  msg .. '_'; -- let us know we processed it
    else
      msg = nick .. " " .. msg;
    --  msg =  "* " .. msg;
    end
	end
  return false, msg , author, ...;
end


function GuildNick.Count()

 local count = 0
  for _ in pairs(GuildNick.nickTable) do count = count + 1 end
  return count
end