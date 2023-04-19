local currentIndex = 1
local charId = 0

function LoginNextCharacter()
  print("currentIndex: ", currentIndex)
  if currentIndex > #game.Characters then currentIndex = 1 end
  --if game.State ~= ClientState.Character_Select_Screen then game.Actions.Logout() end
  print("LoginChar: ", game.Characters[currentIndex].Name)
  game.Actions.Login(game.Characters[currentIndex].Id)
  currentIndex = currentIndex + 1
end

function HandleLogin()
  charId = game.CharacterId
  print("HandleLogin", charId, game.Character.Weenie.Name)
  game.World.OnTell.Add(function (chat_evt)
    print("Got Chat:", chat_evt.Message)
    if chat_evt.Message == "login next" then
      game.Actions.Logout()
    end
  end)
end

game.OnStateChanged.Add(function(state_evt)
  print("game.State: ", game.State)
  if state_evt.NewState == ClientState.In_Game then
    HandleLogin()
  end
  if state_evt.NewState == ClientState.Character_Select_Screen then
    LoginNextCharacter()
  end
end)

if game.State == ClientState.Character_Select_Screen then
  LoginNextCharacter()
elseif game.State == ClientState.In_Game then
  HandleLogin()
end