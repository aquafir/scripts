--Automatically confirm all
game.World.OnConfirmationRequest.Add(function(evt)
  print("Got Confirmation Popup: ", evt.Type, evt.Text)
  evt.ClickYes = true
end)
