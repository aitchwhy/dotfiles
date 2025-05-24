"use strict";var y=Object.create;var i=Object.defineProperty;var h=Object.getOwnPropertyDescriptor;var u=Object.getOwnPropertyNames;var f=Object.getPrototypeOf,w=Object.prototype.hasOwnProperty;var G=(t,e)=>{for(var n in e)i(t,n,{get:e[n],enumerable:!0})},l=(t,e,n,s)=>{if(e&&typeof e=="object"||typeof e=="function")for(let o of u(e))!w.call(t,o)&&o!==n&&i(t,o,{get:()=>e[o],enumerable:!(s=h(e,o))||s.enumerable});return t};var v=(t,e,n)=>(n=t!=null?y(f(t)):{},l(e||!t||!t.__esModule?i(n,"default",{value:t,enumerable:!0}):n,t)),x=t=>l(i({},"__esModule",{value:!0}),t);var g={};G(g,{default:()=>m});module.exports=x(g);var a=v(require("node:process"),1),c=require("node:util"),r=require("node:child_process"),S=(0,c.promisify)(r.execFile);async function p(t,{humanReadableOutput:e=!0}={}){if(a.default.platform!=="darwin")throw new Error("macOS only");let n=e?[]:["-ss"],{stdout:s}=await S("osascript",["-e",t,n]);return s.trim()}var d=`
on replaceTilde(theText)
	set AppleScript's text item delimiters to "~"
	set theTextItems to every text item of theText
	set AppleScript's text item delimiters to "~ "
	set newText to theTextItems as text
	set AppleScript's text item delimiters to "" -- Reset delimiters
	return newText
end replaceTilde

use F : application "Finder"
on getSelectedFolderPath()
	tell (F's selection as list) \xAC
		to if (count) is 1 \xAC
		and the first item's class is folder \xAC
		then return the POSIX path \xAC
		of (the first item as alias)
	
	return POSIX path of (F's insertion location as alias)
end getSelectedFolderPath

set currentPath to replaceTilde(quoted form of getSelectedFolderPath())

tell application "System Events"
	set isGhosttyRunning to exists (processes where name is "Ghostty")
end tell

tell application "Ghostty"
	if not isGhosttyRunning then
		activate
		tell application "System Events"
			tell process "Ghostty"
				delay 0.2
				keystroke "cd " & currentPath & " " & return
				keystroke "clear" & return
			end tell
		end tell
	else
		-- If Ghostty is already running, activate Finder first then activate Ghostty and send Cmd+N to create new window
		tell application "Finder" to activate
		activate
		tell application "System Events"
			tell process "Ghostty"
				keystroke "n" using {command down}
				delay 0.2
				keystroke "cd " & currentPath & " " & return
				keystroke "clear" & return
			end tell
		end tell
	end if
end tell`;async function m(){await p(d)}
