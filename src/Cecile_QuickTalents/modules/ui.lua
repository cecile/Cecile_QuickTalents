----------------------------------------------------------------------------------------------------
-- ui module

--get the engine and create the module
local AddOnName,Engine = ...;
local mod = Engine.AddOn:NewModule("ui");

--get the locale
--local L=Engine.Locale;

--module defaults
mod.Defaults = {
  profile = {
    buttonFont = {
      name = "Cecile",
      size = 20,
      color = {
          r = 1,
          g = 1,
          b = 1,
          a = 1
      },
    },
    titleFont = {
      name = "Cecile",
      size = 30,
      color = {
          r = 0,
          g = 0,
          b = 0,
          a = 1
      },
    },
    specFont = {
      name = "Cecile",
      size = 20,
      color = {
          r = 0,
          g = 0,
          b = 0,
          a = 1
      },
    },
    bossFont = {
      name = "Cecile",
      size = 16,
      color = {
          r = 1,
          g = 1,
          b = 1,
          a = 1
      },
    },
    cancelColor = {
      r = 0.7,
      g = 0.0,
      b = 0.0
    },
    activateColor = {
      r = 0.0,
      g = 0.0,
      b = 0.7
    },
    raidColor = {
      r = 0.0,
      g = 0.7,
      b = 0.0
    },
    windowColor = {
      r = 0.5,
      g = 0.5,
      b = 0.5,
      a = 0.7
    },
    borderColor = {
      r = 0.0,
      g = 0.0,
      b = 0.0
    },
    highlightColor = {
      r = 1.0,
      g = 1.0,
      b = 1.0,
      a = 0.1
    }
  }
}

--debug
local debug = Engine.AddOn:GetModule("debug");

--database
local database = Engine.AddOn:GetModule("database");

--sharemedia
local LSM = LibStub("LibSharedMedia-3.0");

function mod.CreateFont(font)

  --get the font settings
  local fontSettings = Engine.Profile.ui[font];

  local fontName = fontSettings.name;
  local fontSize = fontSettings.size;
  local fontColor = fontSettings.color;

  local id = string.format("%s_%d_%f_%f_%f_%f", fontName, fontSize, fontColor.r, fontColor.g, fontColor.b, fontColor.a)

  local fontObject= _G.CreateFont(id);

  fontObject:SetFont(LSM:Fetch("font", fontName), fontSize)
  fontObject:SetTextColor(fontColor.r, fontColor.g, fontColor.b, fontColor.a)

  return fontObject;
end

function mod:LoadProfileSettings()


  self.buttonFont = mod.CreateFont("buttonFont");
  self.titleFont = mod.CreateFont("titleFont");
  self.specFont = mod.CreateFont("specFont");
  self.bossFont = mod.CreateFont("bossFont");

  self.cancelColor = Engine.Profile.ui.cancelColor;
  self.raidColor = Engine.Profile.ui.raidColor;
  self.activateColor = Engine.Profile.ui.activateColor;
  self.windowColor = Engine.Profile.ui.windowColor;
  self.borderColor = Engine.Profile.ui.borderColor;
  self.highlightColor = Engine.Profile.ui.highlightColor;
  self.label = _G.GetAddOnMetadata(AddOnName, "Title")
end

function mod.SaveProfileSettings()


end

function mod:OnProfileChanged()

  debug("profile changed");

  self:LoadProfileSettings();
  self:SelectRaid();

end

--Flattern a ui object removing regions
function mod.Flattern(object)

  local BlizzardRegions = {
    'Left',
    'Middle',
    'Right',
    'Mid',
    'LeftDisabled',
    'MiddleDisabled',
    'RightDisabled',
  }

  local name = object:GetName()

  if name then
    for _, Region in pairs(BlizzardRegions) do
      if _G[name..Region] then
        _G[name..Region]:SetAlpha(0)
      end
    end
  end

  for _, Region in pairs(BlizzardRegions) do
    if object[Region] then
      object[Region]:SetAlpha(0)
    end
  end

  if object.SetNormalTexture then object:SetNormalTexture("") end
  if object.SetPushedTexture then object:SetPushedTexture("") end
  if object.SetDisabledTexture then object:SetDisabledTexture("") end

  if object.icon then
    local fit = 0.075;
    object.icon:SetAllPoints();
    object.icon:SetTexCoord(fit, 1-fit, fit, 1-fit);
  end

end

--create a border in a direction,size, and color
function mod.CreateBorder(object,direction,r,g,b)

  --the size does not have direction
  local size = math.abs(direction);

  --get the frame border if its has it
  local border = object.border;

  --if has not border create it
  if border == nil then
    border = _G.CreateFrame("Frame", nil, object);
  end

  --if has anchors remove them
  if border:GetPoint() then
    border:ClearAllPoints();
  end

  --set the anchors base on our direction
  border:SetPoint('TOPLEFT', object, 'TOPLEFT', direction, -direction)
  border:SetPoint('BOTTOMRIGHT', object, 'BOTTOMRIGHT', -direction, direction)

  --se the right frame level
  border:SetFrameLevel(object:GetFrameLevel() + 1)

  --set a solid backdrop with right insets
  border:SetBackdrop({
    edgeFile = [[Interface\BUTTONS\WHITE8X8]],
    edgeSize = size,
    insets = { left = size, right = size, top = size, bottom = size }
  });

  --set the backdrop color
  border:SetBackdropBorderColor(r, g, b, 1)

  --store border
  object.border = border;
end

function mod.SetBorderColor(object,r,g,b)

  if object.border then
    object.border:SetBackdropBorderColor(r, g, b, 1)
  end

end

--se the frame to be just a single color frame
function mod.SetSolidColor(object, r,g,b,a)

  --if does not have a texture, create it
  if object.texture == nil then
    object.texture = object:CreateTexture(nil, "BACKGROUND");
    object.texture:SetAllPoints(true);
  end


  object.texture:SetColorTexture(r,g,b,a);

end

--create a UI object and inject our functions
function mod.CreateUIObject(class,parent,name,template)

  local frame = _G.CreateFrame(class, name, parent, template);

  frame.CreateBorder = mod.CreateBorder;
  frame.SetBorderColor = mod.SetBorderColor;
  frame.SetSolidColor = mod.SetSolidColor;
  frame.Flattern = mod.Flattern;

  return frame;
end

function mod:CreateButton(text, width, height, color, name)

  --create main frame
  local frame = self.CreateUIObject("Button",self.mainFrame, name);

  frame:SetSize(width, height);
  frame:SetPoint("CENTER", 0, 0);

  frame:SetSolidColor(color.r, color.g, color.b, 1.0);
  frame:CreateBorder(-2,self.borderColor.r,self.borderColor.r,self.borderColor.r);
  frame:SetNormalFontObject(self.buttonFont);

  -- highlight
  local texHigh = frame:CreateTexture(nil, "BORDER");
  texHigh:SetColorTexture(self.highlightColor.r, self.highlightColor.g, self.highlightColor.b, self.highlightColor.a);
  texHigh:SetAllPoints(true);
  frame:SetHighlightTexture(texHigh);

  frame:SetText(text);

  return frame;

end

function mod:CreateWindow(title, width, height, color)

  local frame = self.CreateUIObject("Frame",_G.UIParent);

  frame:SetSize(width, height);
  frame:SetPoint("CENTER", 0, 0);

  frame:SetSolidColor(color.r, color.g, color.b, color.a);
  frame:CreateBorder(-2,self.borderColor.r,self.borderColor.r,self.borderColor.r);

  frame.label = frame:CreateFontString(nil, "ARTWORK");
  frame.label:SetFontObject(self.titleFont);
  frame.label:SetPoint('TOPLEFT', frame, 'TOPLEFT', 10, -10)
  frame.label:SetText(title);

  frame.spec = frame:CreateFontString(nil, "ARTWORK");
  frame.spec:SetFontObject(self.specFont);
  frame.spec:SetPoint('TOPRIGHT', frame, 'TOPRIGHT', -120, -20)
  frame.spec:SetJustifyH("RIGHT");
  frame.spec:SetText(title);

  frame:SetFrameStrata("FULLSCREEN_DIALOG");

  return frame;

end

function mod:CreateTalentButton(item, number)

  local frame = self.CreateUIObject("Button",item,nil,"ActionButtonTemplate");

  local gap = 6;
  local width = 24;
  local height = 24;

  frame:SetSize(width, height);

  frame.icon:SetTexture("Interface\\Icons\\Temp");
  frame:Flattern();
  frame:CreateBorder(-2,self.borderColor.r,self.borderColor.r,self.borderColor.r);


  local posX = 200+((width+gap)*(number-1));
  local posY = 0;

  frame:SetPoint('TOPLEFT', item, 'TOPLEFT', posX, posY);

  if item.talents == nil then
    item.talents = {};
  end

  item.talents[number] = frame;

  self.number = number;

  return frame;

end


function mod:CreateBossRow(number)

  local frame = _G.CreateFrame("Frame",nil,self.mainFrame);

  local height = 45;

  frame:SetSize(height*2, height);

  frame.label = frame:CreateFontString(nil, "ARTWORK");
  frame.label:SetFontObject(self.bossFont);
  frame.label:SetPoint('TOPLEFT', frame, 'TOPLEFT', 0, 0);
  frame.label:SetText("Super Mega Boss of hell "..number.." :");

  local start = 90;
  local posX = 10;
  local posY = start+(height*(number-1));

  frame:SetPoint('TOPLEFT', self.mainFrame, 'TOPLEFT', posX, -posY);

  for i=1,10 do
    self:CreateTalentButton(frame,i)
  end

  frame.activate = self:CreateButton("activate", 100, height-16, self.activateColor);
  frame.activate:SetPoint('TOPLEFT', frame, 'TOPLEFT', 520, 0);
  frame.activate.number = number;

  mod.SetSolidColor(frame,1,1,1);
  frame.texture:SetTexture("Interface\\EncounterJournal\\UI-EJ-BOSS-Nythendra");

  if self.mainFrame.bosses == nil then
    self.mainFrame.bosses = {};
  end

  self.mainFrame.bosses[number] = frame;

  self.number = number;

  return frame;

end

function mod:SelectRaid(number)

  if number == nil then
    number = mod.selectedRaid or 1;
  end

  for index,tab in pairs(self.mainFrame.raid) do
    if index == number then
      tab:SetAlpha(1);
    else
      tab:SetAlpha(0.2);
    end
  end

  for _,bossFrame in pairs(self.mainFrame.bosses) do
    bossFrame:Hide();
    bossFrame.activate:Hide();
  end

  local bosses = database:GetBosses(number);

  for index,boss in pairs(bosses) do
    local bossFrame = self.mainFrame.bosses[index];
    bossFrame.label:SetText(boss.name);
    bossFrame.texture:SetTexture(boss.texture);
    bossFrame:Show();
    bossFrame.activate:Show();
  end

  mod.selectedRaid = number;

end

function mod.raidClick(raid)

  mod:SelectRaid(raid.number);

  _G.PlaySound("igMainMenuOption");

end

function mod:CreateRaidTab(number)

  local gap = 6;
  local width = 180;
  local height = 30;

  local frame = self:CreateButton("Super Raid Instace "..number..":", width, height, self.raidColor);

  local posX = gap+((width+gap)*(number-1));
  local posY = -50;

  frame:SetPoint('TOPLEFT', self.mainFrame, 'TOPLEFT', posX, posY);

  if self.mainFrame.raid == nil then
    self.mainFrame.raid = {};
  end

  self.mainFrame.raid[number] = frame;

  frame.number = number;

  frame:SetScript("OnClick", self.raidClick);

  return frame;

end


function mod:Hide()

  debug("hiding ui");

  self.mainFrame:Hide();

  _G.ClearOverrideBindings(mod.closeButton);

end

function mod:Show()

  debug("showing ui");

  self:UpdateSpecInfo();
  self.mainFrame:Show();

  _G.SetOverrideBindingClick(self.closeButton, true, "ESCAPE", "CQT_CANCEL_BUTTON", "LeftClick");

end

function mod.closeClick()
  mod:Hide();
  _G.PlaySound("igMainMenuOption");
end

function mod:CreateUI()

  self.mainFrame = mod:CreateWindow(self.label, 680, 550, self.windowColor);

  self.closeButton = self:CreateButton("Close", 100, 40, self.cancelColor, "CQT_CANCEL_BUTTON");
  self.closeButton:SetPoint('TOPRIGHT', self.mainFrame, 'TOPRIGHT', -10, -10);
  self.closeButton:SetScript("OnClick", self.closeClick);

  for i=1,10 do
    self:CreateBossRow(i);
  end

  for i=1,3 do
    self:CreateRaidTab(i);
  end

  --hide main frame
  self.mainFrame:Hide();

end

function mod:SetRaid(index, raid)
  self.mainFrame.raid[index]:SetText(raid.name);
end

function mod:UpdateSpecInfo()
  local activeIndex = _G.GetSpecialization();
  local _, name, _, icon  = _G.GetSpecializationInfo(activeIndex);

  if not name then return; end

  local localclass, myclass = _G.UnitClass("player");

  local classColor = "|c".._G["RAID_CLASS_COLORS"][myclass].colorStr;
  local text = _G.format(classColor..'%s %s|r |T%s:14:14:0:0:64:64:4:60:4:60|t', name, localclass, icon);

  self.mainFrame.spec:SetText(text);

end

function mod.PlayerSpecChange()

  mod:SelectRaid();

  mod:UpdateSpecInfo();

end

function mod:OnInitialize()

  debug("UI module Initialize");

  self:LoadProfileSettings();

  self:CreateUI();

  for index,raid in pairs(database:GetRaids()) do
    mod:SetRaid(index,raid);
  end

  self:SelectRaid();
  mod:UpdateSpecInfo();

  Engine.AddOn:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED",self.PlayerSpecChange);

end

--handle commands
function mod.handleCommand(args)

  --has this module handle the command?
  local handleIt = false;

  --if the command is 'ui'
  if args=="ui" or args=="show" then

    mod:Show();

    --this module has handle the command
    handleIt = true;

  end

  return handleIt;

end
