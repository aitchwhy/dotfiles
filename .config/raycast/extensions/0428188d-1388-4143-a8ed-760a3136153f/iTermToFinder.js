"use strict";var i=Object.defineProperty;var p=Object.getOwnPropertyDescriptor;var l=Object.getOwnPropertyNames;var u=Object.prototype.hasOwnProperty;var w=(e,t)=>{for(var r in t)i(e,r,{get:t[r],enumerable:!0})},m=(e,t,r,s)=>{if(t&&typeof t=="object"||typeof t=="function")for(let o of l(t))!u.call(e,o)&&o!==r&&i(e,o,{get:()=>t[o],enumerable:!(s=p(t,o))||s.enumerable});return e};var f=e=>m(i({},"__esModule",{value:!0}),e);var L={};w(L,{default:()=>d});module.exports=f(L);var n=require("@raycast/api");var c=require("node:child_process");async function a(e){if(process.platform!=="darwin")throw new Error("macOS only");let t=process.env.LC_ALL;delete process.env.LC_ALL;let{stdout:r}=(0,c.spawnSync)("osascript",["-e",e]);return process.env.LC_ALL=t,r.toString()}var d=async()=>{let e=`
      if application "iTerm" is not running then
          return "Not running"
      end if
  
      tell application "iTerm"
      tell the current session of current window
          write text "open -a Finder ./"
      end tell
      end tell
  `;try{let t=await a(e);await(0,n.showToast)(n.Toast.Style.Success,"Done",t)}catch{await(0,n.showToast)(n.Toast.Style.Failure,"Something went wrong")}};
