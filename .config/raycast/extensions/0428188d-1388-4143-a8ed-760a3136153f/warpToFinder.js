"use strict";var s=Object.defineProperty;var i=Object.getOwnPropertyDescriptor;var l=Object.getOwnPropertyNames;var m=Object.prototype.hasOwnProperty;var w=(e,t)=>{for(var o in t)s(e,o,{get:t[o],enumerable:!0})},y=(e,t,o,a)=>{if(t&&typeof t=="object"||typeof t=="function")for(let n of l(t))!m.call(e,n)&&n!==o&&s(e,n,{get:()=>t[n],enumerable:!(a=i(t,n))||a.enumerable});return e};var S=e=>y(s({},"__esModule",{value:!0}),e);var L={};w(L,{default:()=>u});module.exports=S(L);var r=require("@raycast/api");var c=require("node:child_process");async function p(e){if(process.platform!=="darwin")throw new Error("macOS only");let t=process.env.LC_ALL;delete process.env.LC_ALL;let{stdout:o}=(0,c.spawnSync)("osascript",["-e",e]);return process.env.LC_ALL=t,o.toString()}var u=async()=>{let e=`
      tell application "Warp" to activate
      tell application "System Events"
        keystroke "open -a Finder ./"
        key code 36
      end tell
  `;try{let t=await p(e);await(0,r.showToast)(r.Toast.Style.Success,"Done",t)}catch{await(0,r.showToast)(r.Toast.Style.Failure,"Something went wrong")}};
