

ImGui.BeginTable(label .. "table", columns, IM.ImGuiTableFlags.BordersInner)
ImGui.TableSetupColumn("combo", IM.ImGuiTableColumnFlags.NoHeaderLabel + IM.ImGuiTableColumnFlags.WidthFixed, 250)
ImGui.TableSetupColumn("filterText", IM.ImGuiTableColumnFlags.NoHeaderLabel)
ImGui.TableSetupColumn("enabled", IM.ImGuiTableColumnFlags.NoHeaderLabel)
