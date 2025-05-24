"use strict";var i=Object.defineProperty;var p=Object.getOwnPropertyDescriptor;var l=Object.getOwnPropertyNames;var m=Object.prototype.hasOwnProperty;var u=(e,t)=>{for(var n in t)i(e,n,{get:t[n],enumerable:!0})},w=(e,t,n,a)=>{if(t&&typeof t=="object"||typeof t=="function")for(let o of l(t))!m.call(e,o)&&o!==n&&i(e,o,{get:()=>t[o],enumerable:!(a=p(t,o))||a.enumerable});return e};var y=e=>w(i({},"__esModule",{value:!0}),e);var d={};u(d,{default:()=>S});module.exports=y(d);var r=require("@raycast/api");var s=require("node:child_process");async function c(e){if(process.platform!=="darwin")throw new Error("macOS only");let t=process.env.LC_ALL;delete process.env.LC_ALL;let{stdout:n}=(0,s.spawnSync)("osascript",["-e",e]);return process.env.LC_ALL=t,n.toString()}var S=async()=>{let e=`
      if application "WezTerm" is not running then
      return "Not running"
      end if

      tell application "Finder" to activate
      tell application "WezTerm" to activate
      tell application "System Events"
        keystroke "open -a Finder ./"
        key code 76
      end tell
  `;try{let t=await c(e);await(0,r.showToast)(r.Toast.Style.Success,"Done",t)}catch{await(0,r.showToast)(r.Toast.Style.Failure,"Something went wrong")}};
