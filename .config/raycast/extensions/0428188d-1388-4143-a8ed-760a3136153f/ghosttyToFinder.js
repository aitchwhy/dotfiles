"use strict";var i=Object.defineProperty;var p=Object.getOwnPropertyDescriptor;var l=Object.getOwnPropertyNames;var u=Object.prototype.hasOwnProperty;var y=(e,t)=>{for(var n in t)i(e,n,{get:t[n],enumerable:!0})},m=(e,t,n,a)=>{if(t&&typeof t=="object"||typeof t=="function")for(let r of l(t))!u.call(e,r)&&r!==n&&i(e,r,{get:()=>t[r],enumerable:!(a=p(t,r))||a.enumerable});return e};var w=e=>m(i({},"__esModule",{value:!0}),e);var d={};y(d,{default:()=>S});module.exports=w(d);var o=require("@raycast/api");var s=require("node:child_process");async function c(e){if(process.platform!=="darwin")throw new Error("macOS only");let t=process.env.LC_ALL;delete process.env.LC_ALL;let{stdout:n}=(0,s.spawnSync)("osascript",["-e",e]);return process.env.LC_ALL=t,n.toString()}var S=async()=>{let e=`
      if application "Ghostty" is not running then
      return "Not running"
      end if

      tell application "Finder" to activate
      tell application "Ghostty" to activate
      tell application "System Events"
        keystroke "open -a Finder ./"
        key code 76
      end tell
  `;try{let t=await c(e);await(0,o.showToast)(o.Toast.Style.Success,"Done",t)}catch{await(0,o.showToast)(o.Toast.Style.Failure,"Something went wrong")}};
