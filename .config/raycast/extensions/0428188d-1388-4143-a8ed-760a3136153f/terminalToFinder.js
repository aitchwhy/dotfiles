"use strict";var i=Object.defineProperty;var p=Object.getOwnPropertyDescriptor;var l=Object.getOwnPropertyNames;var u=Object.prototype.hasOwnProperty;var w=(n,t)=>{for(var r in t)i(n,r,{get:t[r],enumerable:!0})},m=(n,t,r,s)=>{if(t&&typeof t=="object"||typeof t=="function")for(let o of l(t))!u.call(n,o)&&o!==r&&i(n,o,{get:()=>t[o],enumerable:!(s=p(t,o))||s.enumerable});return n};var f=n=>m(i({},"__esModule",{value:!0}),n);var L={};w(L,{default:()=>d});module.exports=f(L);var e=require("@raycast/api");var a=require("node:child_process");async function c(n){if(process.platform!=="darwin")throw new Error("macOS only");let t=process.env.LC_ALL;delete process.env.LC_ALL;let{stdout:r}=(0,a.spawnSync)("osascript",["-e",n]);return process.env.LC_ALL=t,r.toString()}var d=async()=>{let n=`
      if application "Terminal" is not running then
          return "Not running"
      end if
  
      tell application "Terminal"
      do script "open -a Finder ./" in first window
      end tell
  `;try{let t=await c(n);await(0,e.showToast)(e.Toast.Style.Success,"Done",t)}catch{await(0,e.showToast)(e.Toast.Style.Failure,"Something went wrong")}};
