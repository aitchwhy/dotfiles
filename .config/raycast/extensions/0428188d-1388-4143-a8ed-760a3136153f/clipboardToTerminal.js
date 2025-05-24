"use strict";var i=Object.defineProperty;var p=Object.getOwnPropertyDescriptor;var l=Object.getOwnPropertyNames;var d=Object.prototype.hasOwnProperty;var m=(e,t)=>{for(var o in t)i(e,o,{get:t[o],enumerable:!0})},w=(e,t,o,n)=>{if(t&&typeof t=="object"||typeof t=="function")for(let r of l(t))!d.call(e,r)&&r!==o&&i(e,r,{get:()=>t[r],enumerable:!(n=p(t,r))||n.enumerable});return e};var f=e=>w(i({},"__esModule",{value:!0}),e);var L={};m(L,{default:()=>y});module.exports=f(L);var s=require("@raycast/api");var a=require("node:child_process");async function c(e){if(process.platform!=="darwin")throw new Error("macOS only");let t=process.env.LC_ALL;delete process.env.LC_ALL;let{stdout:o}=(0,a.spawnSync)("osascript",["-e",e]);return process.env.LC_ALL=t,o.toString()}var y=async()=>{let t=`
      tell application "System Events"
      set pathList to "${await s.Clipboard.readText()}"
      if not (exists (processes where name is "Terminal")) then
          do shell script "open -a Terminal " & pathList
      else
          tell application "Terminal"
          activate
          if (count of windows) is 0 then
              do script ("cd " & pathList)
          else
              tell application "System Events" to tell process "Terminal.app" to keystroke "t" using command down
              delay 1
              do script ("cd " & pathList) in first window
          end if
          end tell
      end if
      end tell
  `;try{let o=await c(t);await(0,s.showToast)(s.Toast.Style.Success,"Done",o)}catch{await(0,s.showToast)(s.Toast.Style.Failure,"Something went wrong")}};
