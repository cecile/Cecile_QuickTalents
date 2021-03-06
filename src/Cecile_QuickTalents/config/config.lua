----------------------------------------------------------------------------------------------------
-- Handle add-on configuration
--

--get the engine & Add-on
local Engine = select(2,...);
local AddOn = Engine.AddOn;

--load libraries
local AceConfig = LibStub("AceConfig-3.0");
local AceConfigDialog = LibStub("AceConfigDialog-3.0");
local AceDB = LibStub("AceDB-3.0");
local AceDBOptions = LibStub("AceDBOptions-3.0");

--get locale
local L = Engine.Locale;

--defaults
Engine.DB = {};
Engine.DB.profile={};
Engine.Profile = Engine.DB.profile;

--return two slash commands from a add-on name, for example Cecile_ExampleAddon will return cea & cecile_ea
function AddOn.GetSlashFromName(name)

  local slash1 = "";
  local slash2 = "";

  local c;
  local picknext = true;
  local pickedfirstspace = false;

  for i = 1, string.len(name) do

    c = string.sub(name,i,i);

    if (picknext) then
      slash1 = slash1 .. string.lower(c);
      if pickedfirstspace then
        slash2 = slash2 .. string.lower(c);
      end
      picknext = false;
    else
      if (c=="_") or (c==" ") then
        picknext = true;
        pickedfirstspace = true;
        slash2 =  slash2..string.lower(string.sub(name,1,i-1)).."_";
      elseif (c==string.upper(c)) then
        slash1 = slash1 .. string.lower(c);
        if pickedfirstspace then
          slash2 = slash2 .. string.lower(c);
        end
      end
    end
  end
  if not pickedfirstspace then
    slash2 = slash2 .. string.lower(name);
  end

  return slash1,slash2;
end

function AddOn:SetupDefaults(object,parent)

  --goes trough all the modules
  for name,module in pairs(object.modules) do

    --if this module has defaults
    if(module.Defaults) then

      --get all defaults tables of the module andd add then to the global defaults
      for databaseName,databaseTable in pairs(module.Defaults) do

        if parent then
          Engine.Defaults[databaseName][parent][name] = databaseTable;

        else
          Engine.Defaults[databaseName][name] = databaseTable;
        end

      end

    end

    if not parent then
      self:SetupDefaults(module,name);
    end

  end

end

--setup options
function AddOn:SetupOptions()

  --setup modules default
  self:SetupDefaults(self);

  --create database
  Engine.DB = AceDB:New(Engine.Name.."DB", Engine.Defaults, true);
  Engine.GLOBAL = _G[Engine.Name.."DB"];

  --set profile
  Engine.Profile = Engine.DB.profile;

  --get the slash commands
  Engine.slash1,Engine.slash2 = self.GetSlashFromName(Engine.Name);

  -- Create slash commands
  _G["SLASH_"..Engine.Name.."1"] = "/"..Engine.slash1;
  _G["SLASH_"..Engine.Name.."2"] = "/"..Engine.slash2;
  _G.SlashCmdList[Engine.Name] = self.HandleCommands;

end

--create options for blizzard ui
function AddOn:RegisterBlizzardOptions()

  --local vars
  local sorted = {};

  --get version
  local Version = self:GetModule("version");

  --register the table and add it to blizzar config ui
  AceConfig:RegisterOptionsTable(Engine.Name,Engine.Options);
  AceConfigDialog:AddToBlizOptions(Engine.Name,Version.Title);

  --goes trough all the modules
  for _ , module in pairs(self.modules) do

    if module.Options then
      table.insert(sorted,module.Options);
    end

  end

  --sort by order
  table.sort(sorted, function(a,b) return a.order < b.order end);

  --go trouh the table
  for k,v in pairs(sorted) do

    --register the table and add it to blizzar config ui
    AceConfig:RegisterOptionsTable(Engine.Name..k, v);
    AceConfigDialog:AddToBlizOptions(Engine.Name..k,v.name,Version.Title);

  end

  --register profile changes callbacks
  Engine.DB.RegisterCallback(self, "OnProfileChanged", "OnProfileChanged");
  Engine.DB.RegisterCallback(self, "OnProfileCopied", "OnProfileChanged");
  Engine.DB.RegisterCallback(self, "OnProfileReset", "OnProfileChanged");

  --create profile options
  local profileOptions = AceDBOptions:GetOptionsTable(Engine.DB);
  profileOptions.name = L["PROFILES"];

  --register the table and add it to blizzar config ui
  AceConfig:RegisterOptionsTable(Engine.Name.."Profile", profileOptions);
  AceConfigDialog:AddToBlizOptions(Engine.Name.."Profile",L["PROFILES"],Version.Title);

end

function AddOn:OpenBlizzardConfig()

  self:GetModule("ui"):Hide();

    --get version
  local Version = self:GetModule("version");

  --open config twice (yes, if not does not work always)
  _G.InterfaceOptionsFrame_OpenToCategory(Version.Title);
  _G.InterfaceOptionsFrame_OpenToCategory(Version.Title);
end

-- Handle commands
function AddOn.HandleCommands(args)
  --if not parameters show configuration
  if args == nil then
    AddOn:OpenBlizzardConfig()
  else

    --to check if any module has handle this command
    local handleByModule = false;

    --goes trough the modules
    for _ , module in pairs(AddOn.modules) do

      --if any module has a HandleCommands
      if module.handleCommand and type(module.handleCommand)=="function" then

        --call it and mark that a module has handle it
        handleByModule = handleByModule or module.handleCommand(args);

      end

    end

    --if not module has handle it, open configuration
    if not handleByModule then

      AddOn:OpenBlizzardConfig();

    end

  end
end

-- Called after profile changed
function AddOn:OnProfileChanged(event, database)

  --set new profile
  Engine.Profile = database.profile;

  --if any module has a OnProfileChange trigger it
  for _ , module in pairs(self.modules) do

    if module.OnProfileChanged and type(module.OnProfileChanged)=="function" then
      module:OnProfileChanged(event);
    end

  end

end

function AddOn:NotifyChange(object)

  --if any module has a OnProfileChange trigger it
  for _ ,module in pairs(object.modules) do

    if module.LoadProfileSettings and type(module.LoadProfileSettings)=="function" then
      module:LoadProfileSettings();
    end

    self:NotifyChange(module);

  end

end

function AddOn:OnCfgChange()

  self:GetModule("ui"):Hide();

  self:NotifyChange(self);

end
