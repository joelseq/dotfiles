on run argv
	if (count of argv) < 5 or ((count of argv) - 2) mod 3 is not 0 then error "usage: hdworkday.applescript <launcher> <workday|tab> (<name> <target> <connected>)+"

	set launcher to item 1 of argv
	set launchMode to item 2 of argv
	if launchMode is not "workday" and launchMode is not "tab" then error "unknown launch mode: " & launchMode

	set firstTab to missing value
	set targetWindow to missing value
	set reusedNames to {}
	set createdNames to {}

	tell application "Ghostty"
		activate

		repeat with argumentIndex from 3 to (count of argv) by 3
			set connectionName to item argumentIndex of argv
			set connectionTarget to item (argumentIndex + 1) of argv
			set isConnected to item (argumentIndex + 2) of argv is "true"
			set existingMatch to my findTab(connectionName)

			if existingMatch is not missing value and isConnected then
				set connectionTab to item 1 of existingMatch
				if targetWindow is missing value then set targetWindow to item 2 of existingMatch
				set end of reusedNames to connectionName
			else
				if existingMatch is not missing value then
					set staleTab to item 1 of existingMatch
					set staleTerminal to focused terminal of staleTab
					perform action ("set_tab_title:" & connectionName & " (disconnected)") on staleTerminal
				end if
				set tabConfig to new surface configuration
				set command of tabConfig to quoted form of launcher & " connect-target " & quoted form of connectionName & " " & quoted form of connectionTarget
				set wait after command of tabConfig to false

				if targetWindow is missing value then
					if launchMode is "tab" and (count of windows) > 0 then
						set targetWindow to front window
						set connectionTab to new tab in targetWindow with configuration tabConfig
					else
						set targetWindow to new window with configuration tabConfig
						set connectionTab to selected tab of targetWindow
					end if
				else
					set connectionTab to new tab in targetWindow with configuration tabConfig
				end if

				set connectionTerminal to focused terminal of connectionTab
				perform action ("set_tab_title:" & connectionName) on connectionTerminal
				set end of createdNames to connectionName
			end if

			if firstTab is missing value then set firstTab to connectionTab
		end repeat

		select tab firstTab
		focus focused terminal of firstTab
	end tell

	return "reused: " & my joinList(reusedNames) & "; created: " & my joinList(createdNames)
end run

on findTab(tabName)
	tell application "Ghostty"
		repeat with ghosttyWindow in windows
			repeat with ghosttyTab in tabs of ghosttyWindow
				if name of ghosttyTab is tabName then return {ghosttyTab, ghosttyWindow}
			end repeat
		end repeat
	end tell
	return missing value
end findTab

on joinList(valuesList)
	if (count of valuesList) is 0 then return "none"
	set AppleScript's text item delimiters to ", "
	set joinedValues to valuesList as text
	set AppleScript's text item delimiters to ""
	return joinedValues
end joinList
