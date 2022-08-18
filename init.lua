super = {"ctrl", "shift"}

windowHistory = hs.window.focusedWindow()


---
--- dmg hammerspoon
---

local obj={}
obj.__index = obj

-- metadata

obj.name = "dmg"
obj.version = "0.1"
obj.author = "dmg <dmg@uvic.ca>"
obj.homepage = "https://github.com/dmgerman/dmg-spoon"
obj.license = "MIT - https://opensource.org/licenses/MIT"

-- do this at the beginning in case we have an error
hs.hotkey.bind(
   {"cmd", "alt", "ctrl"}, "R",
   function() hs.reload()
end)





-- make sure it is loaded
--hs.loadSpoon("WinWin")

obj.wstate = {}





function obj:print_table0(t)
   for i,v in ipairs(t) do
      print(i, v)
   end
end


function obj:print_table(t, f)
    for i,v in ipairs(t) do
       print(i, f(v))
    end
end

function obj:print_windows()
   function w_info(w)
      return w:title() .. w:application():name()
   end
   obj:print_table(hs.window.visibleWindows(), w_info)
end

--function obj:print_windows()
-- for i,v in ipairs(hs.window.visibleWindows()) do
--       print(i, v:title(), v:application():name())
--   end
--end

------------------


-------------------------------
-- select window by title

theWindows = hs.window.filter.new()
theWindows:setDefaultFilter{}
theWindows:setSortOrder(hs.window.filter.sortByFocusedLast)
obj.currentWindows = {}
obj.previousSelection = nil  -- the idea is that one switches back and forth between two windows all the time

for i,v in ipairs(theWindows:getWindows()) do
   table.insert(obj.currentWindows, v)
end

function obj:find_window_by_title(t)
   for i,v in ipairs(obj.currentWindows) do
      if string.find(v:title(), t) then
         return v
      end
   end
   return nil
end

function obj:focus_by_title(t)
   w = obj:find_window_by_title(t)
   if w then
    window = w

    if hs.window.focusedWindow() == window then
        window = windowHistory
    end

    if window ~= nil then 
        windowHistory = hs.window.focusedWindow()
        hs.mouse.absolutePosition(window:frame().center)
        window:focus()
    end
   end
   return w
end

function obj:focus_by_app(appName)
   print(' [' .. appName ..']')
   for i,v in ipairs(obj.currentWindows) do
      print('           [' .. v:application():name() .. ']')
      if string.find(v:application():name(), appName) then
         print("Focusing window" .. v:title())

        window = v

         if hs.window.focusedWindow() == window then
            window = windowHistory
        end

        if window ~= nil then 
            windowHistory = hs.window.focusedWindow()
            hs.mouse.absolutePosition(window:frame().center)
            window:focus()
        end



         return v
      end
   end
   return nil
end



local function callback_window_created(w, appName, event)

   if event == "windowDestroyed" then
--      print("deleting from windows-----------------", w)
      for i,v in ipairs(obj.currentWindows) do
         if v == w then
            table.remove(obj.currentWindows, i)
            return
         end
      end
--      print("Not found .................. ", w)
--      obj:print_table0(obj.currentWindows)
--      print("Not found ............ :()", w)
      return
   end
   if event == "windowCreated" then
--      print("inserting into windows.........", w)
      table.insert(obj.currentWindows, 1, w)
      return
   end
   if event == "windowFocused" then
      --otherwise is equivalent to delete and then create
      callback_window_created(w, appName, "windowDestroyed")
      callback_window_created(w, appName, "windowCreated")
--      obj:print_table0(obj.currentWindows)
   end
end
theWindows:subscribe(hs.window.filter.windowCreated, callback_window_created)
theWindows:subscribe(hs.window.filter.windowDestroyed, callback_window_created)
theWindows:subscribe(hs.window.filter.windowFocused, callback_window_created)

local function list_window_choices()
   local windowChoices = {}
--   for i,v in ipairs(theWindows:getWindows()) do
   for i,w in ipairs(obj.currentWindows) do
      if w ~= hs.window.focusedWindow() then
         table.insert(windowChoices, {
                         text = w:title() .. "--" .. w:application():name(),
                         subText = w:application():name(),
                         uuid = i,
                         image = hs.image.imageFromAppBundle(w:application():bundleID()),
                         win=w})
      end
   end
   return windowChoices;
end

local windowChooser = hs.chooser.new(function(choice)
      if not choice then hs.alert.show("Nothing to focus"); return end
      local v = choice["win"]
      if v then
         v:focus()
      else
         hs.alert.show("unable fo focus " .. name)
      end
end)


hs.hotkey.bind(super, "b", function()
      local windowChoices = list_window_choices()
      windowChooser:choices(windowChoices)
      --windowChooser:placeholderText('')
      windowChooser:rows(12)         
      windowChooser:query(nil)         
      windowChooser:show()
end)

-------------------
function obj:isfullscreen(cwin)
   local cwin = hs.window.focusedWindow()
   local cscreen = cwin:screen()
   local ff = cscreen:frame()
   local wf = cwin:frame()
   return (ff.w < wf.w + 20) and (ff.h < wf.h + 20)
end

function obj:isvfullscreen(cwin)
   local cwin = hs.window.focusedWindow()
   local cscreen = cwin:screen()
   local ff = cscreen:frame()
   local wf = cwin:frame()
   return (ff.h < wf.h + 20)
end


function obj:fullscreen()
   local cwin = hs.window.focusedWindow()

   local cscreen = cwin:screen()
   local cres = cscreen:frame()
   local cwinid = cwin:id()
   local winf = cwin:frame()

   if obj.isfullscreen(cwin) then
      local oldwinf = obj.wstate[cwinid]
      if oldwinf then
         cwin:setFrame(oldwinf)
      else
         --         obj.wstate[cwinid] = winf
         cwin:setFrame({x=cres.x/2, y=cres.y/2, w=cres.w/2, h=cres.h/2})
      end
   else
      -- set  to full screen
      obj.wstate[cwinid] = winf
      cwin:setFrame({x=cres.x, y=cres.y, w=cres.w, h=cres.h})
   end
end

function obj:verticalfullscreen()
   local cwin = hs.window.focusedWindow()

   local cscreen = cwin:screen()
   local cres = cscreen:frame()
   local cwinid = cwin:id()
   local winf = cwin:frame()

   if obj.isvfullscreen(cwin) then

      local oldwinf = obj.wstate[cwinid]
      if oldwinf then
         cwin:setFrame(oldwinf)
      else
         cwin:setFrame({x=cres.x/2, y=cres.y/2, w=cres.w/2, h=cres.h/2})
      end
   else
      obj.wstate[cwinid] = winf
      cwin:setFrame({x=winf.x, y=cres.y, w=winf.w, h=cres.h})
      
   end
end



-- dmgmash = {"alt"}
-- dmgmashshift = {"alt", 'shift'}


-- hs.hotkey.bind(dmgmash, "m", function()
--                   print("Calling full screen")
--                   obj.fullscreen()
-- end)

-- hs.hotkey.bind(dmgmash, "v", function()
--                   print("Calling vertical full screen")
--                   obj.verticalfullscreen()
-- end)

-- hs.hotkey.bind(dmgmash, "a", function()
--                   hs.window.filter.focusWest()
-- end)

-- hs.hotkey.bind(dmgmash, "0", function()
--                   hs.window.frontmostWindow():sendToBack()
-- end)


-- hs.hotkey.bind(dmgmash, "f", function()
--                   hs.window.filter.focusEast()
-- end)

-- hs.hotkey.bind(dmgmash, "n", function()
--                   hs.window.filter.focusNorth()
-- end)

-- hs.hotkey.bind(dmgmash, "p", function()
--                   hs.window.filter.focusSouth()
-- end)

-- hs.hotkey.bind(super, "g", function()
--                   obj:focus_by_title(emacsTitle)
-- end)
-- hs.hotkey.bind(super, "y", function()
--                   obj:focus_by_title("youtube")
-- end)



hs.hotkey.bind(super, "w", function()
    obj:focus_by_app("Code")
end)                  
hs.hotkey.bind(super, "q", function()
    obj:focus_by_app("Google Chrome")
end)                  
hs.hotkey.bind(super, "e", function()
    obj:focus_by_app("iTerm")
end)                  
hs.hotkey.bind(super, "r", function()
   obj:focus_by_app("Xcode")
end)                  
hs.hotkey.bind(super, "t", function()
   obj:focus_by_title("Castle Debug")
end)                  

hs.hotkey.bind(super, "a", function()
    obj:focus_by_app("Messages")
end)                  
hs.hotkey.bind(super, "s", function()
    obj:focus_by_app("Slack")
end)                  
hs.hotkey.bind(super, "d", function()
    obj:focus_by_app("Discord")
end)                  
hs.hotkey.bind(super, "f", function()
    obj:focus_by_app("Figma")
end)                  

hs.hotkey.bind(super, "z", function()
   obj:focus_by_title("Zoom")
end)   



;;;;;;;;;;;;;;;;
   
function dmgMoveAndResize(option)
    local cwin = hs.window.focusedWindow()
    if cwin then
        local cscreen = cwin:screen()
        local cres = cscreen:fullFrame()
        local wf = cwin:frame()
        if option == "1-3rd" then
           cwin:setFrame({x=cres.x, y=cres.y, w=cres.w/3, h=cres.h})
        elseif option == "2-3rd" then
           cwin:setFrame({x=cres.x + cres.w/3, y=cres.y, w=cres.w/3, h=cres.h})
        elseif  option == "3-3rd" then
           cwin:setFrame({x=cres.x + cres.w*2/3, y=cres.y, w=cres.w/3, h=cres.h})
        end
    else
        hs.alert.show("No focused window!")
    end
end

hs.hotkey.bind(super, "6", function()
                  dmgMoveAndResize("1-3rd")
end)
hs.hotkey.bind(super, "7", function()
                  dmgMoveAndResize("2-3rd")
end)
hs.hotkey.bind(super, "8", function()
                  dmgMoveAndResize("3-3rd")
end)





-----------------------------------------
-- to go specific destinations

function currentSelection()
   local elem=hs.uielement.focusedElement()
   local sel=nil
   if elem then
      sel=elem:selectedText()
   end
   if (not sel) or (sel == "") then
      hs.eventtap.keyStroke({"cmd"}, "c")
      hs.timer.usleep(20000)
      sel=hs.pasteboard.getContents()
   end
   return (sel or "")
end








hs.alert.show("dmg config loaded")

return obj

-- function toggleWindowFocus(windowName)
--     filter = hs.window.filter.new():setAppFilter(windowName) 
--     return function()
--         for _, window in ipairs(filter:getWindows()) do
--             print(window)
--         end

--         window = filter:getWindows()[1]

--         if hs.window.focusedWindow() == window then
--             window = windowHistory
--         end

--         if window ~= nil then 
--             windowHistory = hs.window.focusedWindow()
--             hs.mouse.absolutePosition(window:frame().center)
--             window:focus()
--         end
--     end
-- end

-- function toggleWindowFocus2(windowName)
--     return function()

--         wf_terminal = hs.window.filter.new{'Terminal','iTerm2'}
--         print(wf_terminal)
--         for _, window in ipairs(wf_terminal:getWindows()) do
--             print(window)
--             if window ~= nil then
--                 if hs.window.focusedWindow() == window then
--                     window = windowHistory
--                     windowHistory = hs.window.focusedWindow()
--                     hs.mouse.absolutePosition(window:frame().center)
--                     window:focus()
--                 end
--                 windowHistory = hs.window.focusedWindow()
--                 hs.mouse.absolutePosition(window:frame().center)
--                 window:focus()
--                 return
--             end
--         end

      
     
--    end
-- end




-- hs.hotkey.bind(super, "w", toggleWindowFocus("Code"))
-- hs.hotkey.bind(super, "q", toggleWindowFocus("Google Chrome"))
-- hs.hotkey.bind(super, "e", toggleWindowFocus2("-zsh"))

-- hs.hotkey.bind(super, "a", toggleWindowFocus("Messages"))
-- hs.hotkey.bind(super, "s", toggleWindowFocus("Slack"))
-- hs.hotkey.bind(super, "d", toggleWindowFocus("Discord"))
-- hs.hotkey.bind(super, "f", toggleWindowFocus("Figma"))

-- hs.hotkey.bind(super, "r", toggleWindowFocus("Xcode"))
-- hs.hotkey.bind(super, "t", toggleWindowFocus("Castle Debug"))


-- hs.hotkey.bind(super, "s", toggleWindowFocus("Spotify"))
