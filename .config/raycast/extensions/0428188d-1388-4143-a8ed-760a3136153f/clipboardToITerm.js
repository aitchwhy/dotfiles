"use strict";var n=Object.defineProperty;var l=Object.getOwnPropertyDescriptor;var p=Object.getOwnPropertyNames;var d=Object.prototype.hasOwnProperty;var w=(t,e)=>{for(var s in e)n(t,s,{get:e[s],enumerable:!0})},m=(t,e,s,r)=>{if(e&&typeof e=="object"||typeof e=="function")for(let o of p(e))!d.call(t,o)&&o!==s&&n(t,o,{get:()=>e[o],enumerable:!(r=l(e,o))||r.enumerable});return t};var f=t=>m(n({},"__esModule",{value:!0}),t);var u={};w(u,{default:()=>h});module.exports=f(u);var i=require("@raycast/api");var a=require("node:child_process");async function c(t){if(process.platform!=="darwin")throw new Error("macOS only");let e=process.env.LC_ALL;delete process.env.LC_ALL;let{stdout:s}=(0,a.spawnSync)("osascript",["-e",t]);return process.env.LC_ALL=e,s.toString()}var h=async()=>{let e=`
      tell application "System Events"
      -- some versions might identify as "iTerm2" instead of "iTerm"
      set isRunning to (exists (processes where name is "iTerm")) or (exists (processes where name is "iTerm2"))
      end tell

      tell application "iTerm"
      activate
      set hasNoWindows to ((count of windows) is 0)
      if isRunning and hasNoWindows then
          create window with default profile
      end if
      select first window

      tell the first window
          if isRunning and hasNoWindows is false then
          create tab with default profile
          end if
          set pathList to "${await i.Clipboard.readText()}"
          set command to "clear; cd " & pathList
          tell current session to write text command
          end tell
      end tell
  `;try{let s=await c(e);await(0,i.showToast)(i.Toast.Style.Success,"Done",s)}catch{await(0,i.showToast)(i.Toast.Style.Failure,"Something went wrong")}};
